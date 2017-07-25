//
//  SingleRestaurantViewController.swift
//  PlateSpace
//
//

import UIKit
import StitchCore
import ExtendedJson
import MongoDBService
import MongoDBODM

protocol SingleRestaurantViewControllerDelegate: ReviewsFlowManagerDelegate {
    func singleRestaurantViewControllerDidUpdate(restaurant: Restaurant)
}

class SingleRestaurantViewController: UIViewController , UITableViewDelegate, UITableViewDataSource, RestaurantMainInfoTableViewCellDelegate, AddReviewTableViewCellDelegate, SingleReviewTableViewCellDelegate, RateNowTableViewCellDelegate, CreateReviewViewControllerDelegate, ReviewsFlowManagerDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    /// A single restaurant which is being viewed
    var restaurant: Restaurant?
    
    /// An optional review (exists if the user has reviewed or rated this restaurant)
    private var userReview: Review?
    
    /// Fetched reviews on this restaurant
    private var reviews: [Review]?
    
    /// The rating the user has left (either now or before)
    /// If the user has just rated, it will not be saved until the screen is closed or a review is saved
    private var userRating: Int?
    
    weak var delegate: SingleRestaurantViewControllerDelegate?
    
    private struct Consts {
        
        /// Values
        static let numberOfSections = 6
        
        /// The maximum number of reviews which could be fetched and shown in the reviews sections
        /// Including the user's own review
        static let maxNumberOfShownReviews = 5
    }
    
    enum TableViewSectionType: Int {
        case mainInfo
        case additionalInfo
        case rateNow
        case writeReview
        case userReview
        case otherReviews
    }
        
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "platespace"
        
        /// Fetch the reviews and update the restaurant with new average rating & rating count
        fetchReviews()
        fetchRestaurant()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let backButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "backNormal"), style: .plain, target: self, action: #selector(backButtonPressed))
        navigationItem.leftBarButtonItem = backButtonItem
    }
    
    // MARK: - Actions
    
    @objc private func backButtonPressed(){
        if let rating = userRating, rating != userReview?.rate {
            /// User rating was changed and not saved
            let review = reviewModel()
            review.rate = rating
            
            /// Save rating, let the delegate handle the result
            ReviewsFlowManager.shared.delegate = delegate

            saveOrUpdateUserReview(review)
        }
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Fetch Reviews
    
    private func fetchReviews() {
        guard
            let restaurantId = restaurant?.objectId,
            let userId = MongoDBManager.shared.stitchClient.auth?.userId
            else {
            print("Cannor fetch reviews, no restaurant id / user id")
            return
        }
        
        /// The total reviews we want to show. Start with the default number
        var reviewCountLimit = Consts.maxNumberOfShownReviews
        
        /// A criteria which limits the query to reviews / rating by this user
        let userCriteria = userReviewsCriteria(forRestaurantId: restaurantId, userId: userId)
        
        /// A criteria which limits the query to reviews by other users (not including review models which only contain a rating)
        let otherUsersCriteria = otherUsersReviewsCriteria(forRestaurantId: restaurantId, userId: userId)
        
        let queryUserReviews = Query<Review>(criteria: userCriteria, mongoDBClient: MongoDBManager.shared.mongoClient)
        
        /// First fetch reviews written on this restaurant, by this user
        queryUserReviews.find().response { [weak self] result in
            
            switch result {
            case .success(let reviews):
                if !reviews.isEmpty {
                    
                    /// Only 1 review per user is allowed for each restaurant, get the first item in the array
                    let userReview = reviews[0]
                    self?.userReview = userReview
                    self?.userRating = userReview.rate
                    
                    /// Reviews and Ratings are in the same model.
                    /// This checks if the user has left a review or just a rating
                    /// If so, reduce 1 from the number of other reviews we wish to fetch
                    if self?.isUserReviewed() == true {
                        reviewCountLimit -= 1
                    }
                }
            case .failure(let error):
                print("error fetching user reviews: \(error.localizedDescription)")
            }
            
            /// Now fetch other users' reviews
            let queryOtherUsers = Query<Review>(criteria: otherUsersCriteria, mongoDBClient: MongoDBManager.shared.mongoClient)
            
            queryOtherUsers.find(limit: reviewCountLimit).response { [weak self] result in
                
                switch result {
                case .success(let reviews):
                    self?.reviews = reviews
                case .failure(let error):
                    print("error fetching other reviews: \(error.localizedDescription)")
                }
                
                /// Whether this call had succeeded or failed, update the table view to show the user review as well (if any)
                self?.tableView.reloadData()
            }
        }
    }
    
    /// Criteria which limits the query to this restaurant, and to this user
    private func userReviewsCriteria(forRestaurantId restaurantId: ObjectId, userId: String) -> Criteria {
        let userReviewsCriteria: Criteria =
                .equals(field: Review.restaurantIdKey, value: restaurantId) &&
                .equals(field: Review.ownerIdKey, value: userId)
        
        return userReviewsCriteria
    }
    
    /// Criteria which limits the query to this restaurant, to other users, and to models that contain a review (will not fetch rating-only models)
    private func otherUsersReviewsCriteria(forRestaurantId restaurantId: ObjectId, userId: String) -> Criteria {
        let otherUsersReviewsCriteria: Criteria =
                .equals(field: Review.restaurantIdKey, value: restaurantId) &&
                .notEqual(field: Review.ownerIdKey, value: userId) &&
                .exists(field: Review.commentKey, value: true) &&
                .notEqual(field: Review.commentKey, value: NSNull())
        
        return otherUsersReviewsCriteria
    }
    
    // MARK: - Fetch Restaurant
    
    func fetchRestaurant() {
        
        /// Fetch an updated instance of this restaurant with updated values
        guard let id = restaurant?.objectId else {return}
        
        let criteria: Criteria = .equals(field: "_id", value: id)
        
        let query = Query<Restaurant>(criteria: criteria, mongoDBClient: MongoDBManager.shared.mongoClient)
            
        query.find().response(completionHandler: { [weak self] result in
            switch result {
            case .success(let restaurants):
                if !restaurants.isEmpty {
                    let restaurant = restaurants[0]
                    
                    /// Update this screen, as well as the restaurants list view controller
                    self?.restaurant = restaurant
                    self?.tableView.reloadData()
                    self?.delegate?.singleRestaurantViewControllerDidUpdate(restaurant: restaurant)
                }
            case .failure(let error):
                print("Error fetching updated restaurant model: \(error.localizedDescription)")
            }
        })
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case TableViewSectionType.mainInfo.rawValue:
            return 179
        case TableViewSectionType.additionalInfo.rawValue:
            return 239
        case TableViewSectionType.rateNow.rawValue:
            return 180
        case TableViewSectionType.writeReview.rawValue:
            return 40
        default:
            return 92
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Consts.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case TableViewSectionType.userReview.rawValue:
            return isUserReviewed() ? 1 : 0
        case TableViewSectionType.otherReviews.rawValue:
            return reviewsCount()
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case TableViewSectionType.mainInfo.rawValue:
            if let mainInfoCell = tableView.dequeueReusableCell(withIdentifier: RestaurantMainInfoTableViewCell.stringFromClass(), for: indexPath) as? RestaurantMainInfoTableViewCell,
                let name = restaurant?.name,
                let imageUrl = restaurant?.image_url {
                mainInfoCell.delegate = self
                mainInfoCell.set(restaurantName: name, openingHours: openingHours(), imageUrl: imageUrl)
                return mainInfoCell
            }
        case TableViewSectionType.additionalInfo.rawValue:
            if let additionalInfoCell = tableView.dequeueReusableCell(withIdentifier: RestaurantAdditionalInfoTabelViewcell.stringFromClass(), for: indexPath) as? RestaurantAdditionalInfoTabelViewcell,
                let address = restaurant?.address,
                let website = restaurant?.website,
                let phone = restaurant?.phone {
                
                additionalInfoCell.set(
                    adress: address,
                    website: website,
                    phone: phone,
                    avarageReview: restaurant?.averageRating ?? 0,
                    numberOfReviews: restaurant?.numberOfRates ?? 0)
                return additionalInfoCell
            }
        case TableViewSectionType.rateNow.rawValue:
            if let rateNowCell = tableView.dequeueReusableCell(withIdentifier: RateNowTableViewCell.stringFromClass(), for: indexPath) as? RateNowTableViewCell {
                rateNowCell.delegate = self
                if let userRating = userReview?.rate {
                    rateNowCell.set(rating: userRating)
                }
                return rateNowCell
            }
        case TableViewSectionType.writeReview.rawValue:
            if let addReviewCell = tableView.dequeueReusableCell(withIdentifier: AddReviewTableViewCell.stringFromClass(), for: indexPath) as? AddReviewTableViewCell {
                addReviewCell.delegate = self
                let enableReviewButton = !MongoDBManager.shared.isAnonymous() && !isUserReviewed()
                addReviewCell.set(isReviewEnabled: enableReviewButton)
                return addReviewCell
            }
        default:
            if let singleReviewCell = tableView.dequeueReusableCell(withIdentifier: SingleReviewTableViewCell.stringFromClass(), for: indexPath) as? SingleReviewTableViewCell,
                let review = review(forIndexPath: indexPath),
                let author = review.nameOfCommenter,
                let date = review.dateOfComment,
                let comment = review.comment {
                let enableEdit = indexPath.section == TableViewSectionType.userReview.rawValue
                singleReviewCell.set(author: author, date: date, content: comment, enableEdit: enableEdit)
                singleReviewCell.delegate = self
                return singleReviewCell
            }
        }
        
        print("Single restaurant VC unsupported cell for index path \(indexPath), or missing required data")
        return UITableViewCell()
    }
    
    // MARK: - RestaurantMainInfoTableViewCellDelegate
    
     func restaurantMainInfoTableViewCellDidPressMapButton() {
        if let mapController = storyboard?.instantiateViewController(withIdentifier: MapViewController.stringFromClass()) as? MapViewController,
            let restaurant = restaurant,
            let name = restaurant.name {
            mapController.set(title: name, restaurants:[restaurant], isTappable: false)
            navigationController?.pushViewController(mapController, animated: true)
        }
    }
    
    // MARK: - AddReviewTableViewCellDelegate
    
    func addReviewTableViewCellDidPressAddReview() {
       loadReviewViewController()
    }
    
    // MARK: - SingleReviewTableViewCellDelegate
    
    func singleReviewTableViewCellDidPressEditReview() {
        loadReviewViewController()
    }
    
    // MARK: - CreateReviewViewControllerDelegate
    
    func createReviewViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    func createReviewViewControllerDidFinishWithReview(review: String) {
        
        /// Create a review model, or update the existing one
        let rev = reviewModel()
        rev.comment = review
        rev.dateOfComment = Date()
        MongoDBManager.shared.userName {
            rev.nameOfCommenter = $0
        }
        
        /// If the user has rated as well, save it in the model
        /// We cannot assign the optional property directly, since assigning nil to the model will create an empty property in the DB
        /// Properties in the model which were not set will not exist in the database
        if let userRating = userRating {
            rev.rate = userRating
        }
        
        dismiss(animated: true, completion: { [weak self] in
            /// Assign the delegate of the ReviewsFlowManager to be informed on save/upadate of the reviews
            ReviewsFlowManager.shared.delegate = self
            
            self?.saveOrUpdateUserReview(rev)
        })
    }
    
    // MARK: - RateNowTableViewCellDelegate
    
    func rateNowTableViewCell(_ cell: RateNowTableViewCell, didRate rate: Int) {
        if MongoDBManager.shared.isAnonymous() {
            /// Anonymous user cannot rate
            cell.set(rating: 0)
            self.showAlert(withTitle: "Attention", message: "In order to test the feature in your App you must first login.")
        } else {
            userRating = rate
        }
        
        tableView.isScrollEnabled = true
    }
    
    func rateNowTableViewCellDidStartRating() {
        /// Disable scrolling while rating so it won't interfere with it (the scroll cancels the rating while leaving the stars marked)
        tableView.isScrollEnabled = false
    }
    
    // MARK: - Private
    
    private func review(forIndexPath indexPath: IndexPath) -> Review? {
        
        switch indexPath.section {
        case TableViewSectionType.userReview.rawValue:
            
            /// Return the user's review
            return userReview
        case TableViewSectionType.otherReviews.rawValue:
            
            /// Return other user's review
            if indexPath.row < reviewsCount() {
                return reviews?[indexPath.row]
            } else {
                print("Unable to find review for row \(indexPath.row)")
                return nil
            }
        default:
            print("Unexpected section requested review")
            return nil
        }
    }
    
    private func isUserReviewModelExists() -> Bool {
        return userReview != nil
    }
    
    /// Return whether or not the user has left a review.
    /// If the user has rated but not reviewed, we would be holding a userReview model with no 'comment'
    private func isUserReviewed() -> Bool {
        return userReview?.comment != nil
    }
    
    /// Get a review model - new or existing
    private func reviewModel() -> Review {
        
        if let userReview = userReview {
            
            /// If a user review exists, return it
            return userReview
        } else {
            
            /// If a user review does not exist, create a new one
            let review = Review(mongoDBClient: MongoDBManager.shared.mongoClient)
            review.owner_id = MongoDBManager.shared.stitchClient.auth?.userId
            review.restaurantId = restaurant?.objectId
            return review
        }
    }
    
    private func loadReviewViewController() {
        if let navController: UINavigationController = storyboard?.instantiateViewController(withIdentifier: "CreateReviewNavigationController") as? UINavigationController,
            let reviewController = navController.viewControllers.first as? CreateReviewViewController {
            reviewController.currentReview = userReview?.comment
            reviewController.delegate = self
            present(navController, animated: true, completion: nil)
        }
    }
    
    private func reviewsCount() -> Int {
        return reviews?.count ?? 0
    }
    
    // MARK: - Opening hours
    
    /// A String representation of the opening hours 
    /// Either 'Open Now' or 'Open HH:mm - HH:mm'
    private func openingHours() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTimeString = formatter.string(from: Date())
        
        guard
            let openString =  restaurant?.openingHours?.start,
            let open = time(fromTimeString: openString),
            let closeString = restaurant?.openingHours?.end,
            let close = time(fromTimeString: closeString),
            let now = time(fromTimeString: currentTimeString)
            else {
                print("Error converting opening hours to int: \(restaurant?.openingHours?.start), \(restaurant?.openingHours?.end)")
                return ""
        }
        
        let openNow = open...close ~= now
        
        return openNow ? "Open Now" : "Open \(openString) - \(closeString)"
    }
    
    private func time(fromTimeString timeString: String) -> Int? {
        let time = timeString.replacingOccurrences(of: ":", with: "")
        
        return Int(time)
    }
    
    // MARK: - Save Reviews
    
    private func saveOrUpdateUserReview(_ review: Review) {
        
        /// If a new review was created, save it
        /// If an old review was edited, update it
        if isUserReviewModelExists() {
            ReviewsFlowManager.shared.update(review: review)
        } else {
            ReviewsFlowManager.shared.save(review: review)
        }
    }
    
    // MARK: - ReviewsFlowManagerDelegate
    
    func reviewsFlowManagerDidSave(review: Review) {
        
        /// Save the review model and update the UI
        userReview = review
        tableView.reloadData()
        showAlert(withTitle: nil, message: "Review saved!")
    }
    
    func reviewsFlowManagerFailedToSaveReview() {
        showErrorAlert(withDescription: "Error saving review")
    }
    
    func reviewsFlowManagerDidUpdateRestaurant() {
        
        /// The restaurant was updated with a new average rating & ratings count 
        fetchRestaurant()
    }

}
