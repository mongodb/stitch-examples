//
//  RestaurantListViewController.swift
//  PlateSpace
//

import UIKit
import CoreLocation
import StitchCore
import ExtendedJson
import MongoDBService
import MongoDBODM
import FBSDKLoginKit

class RestaurantListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LocationUpdateDelegate, LocationAuthorizationDelegate, UISearchBarDelegate, RestaurantFilterViewControllerDelegate, SingleRestaurantViewControllerDelegate, ReviewsFlowManagerDelegate {
    
    // MARK: - Properties

    @IBOutlet private weak var restaurantTableView: UITableView!
    @IBOutlet private weak var filerBarButton: UIBarButtonItem!
    @IBOutlet private weak var mapBarButton: UIBarButtonItem!
    @IBOutlet private weak var logoutBarButton: UIBarButtonItem!
    @IBOutlet private weak var restaurantsSearchBar: UISearchBar!
    @IBOutlet private weak var noResultsLabel: UILabel!
    
    private let locationManager = LocationManager()
    private var userLocation: CLLocation?
    
    /// The complete list of restaurants fetched
    private var restaurants: [Restaurant] = []
    
    /// The current filter applied on the restaurants search
    private var filter: RestaurantFilter = .none
    
    /// The last restaurants distance from our location, for pagination implementation
    private var lastFetchDistance = Consts.fetchMinDistance
    
    /// Restaurants to be excluded from the next pagination fetch.
    /// The fetch is being perfromed by a custom pipeline, and the pagination is sorted by the distance of the restaurants from the user's location.
    /// Since it is possible for multiple restaurants to be in the same distance from the user,
    /// if the next fetch would start from the same distance, this collection would exclude restaurants in this distance that were already fetched
    private var fetchObjectIdsToExclude: [ObjectId] = []
    
    private struct Consts {
        
        /// GeoNear Pipeline
        static let pipelineCommandName        = "geoNearResult"
        static let pipelineResultKey          = "pipelineResult"
        static let pipelineName               = "geoNear"
        
        /// Pipeline Arguments Keys
        static let argsLatitudeKey            = "latitude"
        static let argsLongitudeKey           = "longitude"
        static let argsMinDistanceKey         = "minDistance"
        static let argsLimitKey               = "limit"
        static let argsQueryKey               = "query"
        
        /// Values
        static let fetchMinDistance: Double   = 0.0
        static let fetchLimit: Int            = 25
        static let fetchNextCountFromEnd: Int = 10
        
        /// GeoNear Result Keys
        static let distanceKey                = "dist"
        
        /// Cell heights
        static let cellHeight : CGFloat       = 100.0
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        /// Fetch the current suer location. Once a location has been obtained, we would fetch the restaurants.
        initLocationManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    // MARK: - UI
    
    private func setupUI(){
        navigationController?.isNavigationBarHidden = false
        navigationItem.setHidesBackButton(true, animated: false)
        restaurantsSearchBar.setImage(#imageLiteral(resourceName: "searchIcon"), for: .search, state: .normal)
    }
    
    // MARK: - Fetching
    
    private func fetchRestaurants(paginated: Bool = false) {
        
        guard let location = userLocation else { return }
        
        /// Reset current restaurants and pagination distance if we have a new search which should query all the collection
        if !paginated {
            lastFetchDistance = Consts.fetchMinDistance
            restaurants = []
            restaurantTableView.reloadData()
            showLoadingView(show: true)
        }
       
        /// Build a custom pipeline to support geoNear

        /// Arguments for the geoNear query
        var arguments = Document(dictionary: [
            Consts.argsLatitudeKey    : location.coordinate.latitude,
            Consts.argsLongitudeKey   : location.coordinate.longitude,
            Consts.argsMinDistanceKey : lastFetchDistance,
            Consts.argsLimitKey       : Consts.fetchLimit
        ])
        
        /// Optional query argument for further filtering
        if let criteria = criteria() {
            arguments[Consts.argsQueryKey] = criteria.asDocument
        }
        
        let pipeline = geonearPipeline(withArguments: arguments)
        
        /// Execute the pipeline
        MongoDBManager.shared.stitchClient.executePipeline(pipeline: pipeline).response { [weak self] result in
            self?.showLoadingView(show: false)
            
            switch result {
            case .success(let successResult):
                self?.handlePipelineResult(successResult)
            case .failure(let error):
                print("Geonear pipeline execution failed with error: \(error.localizedDescription)")
                
            }
        }
    }
    
    private func geonearPipeline(withArguments arguments: Document) -> Pipeline {
        /// Pipeline args item specify the structure in which the query results will be returned
        let argsItems: BsonArray = [Document(dictionary: [Consts.pipelineResultKey : "%%vars.\(Consts.pipelineCommandName)"])]
 
        /// The document which is passed to the 'let' field
        let letDocument = Document(dictionary: ["%pipeline" : Document(dictionary: [
            "name" : Consts.pipelineName,
            "args" : arguments
            ])])
        
        /// Build the pipeline
        let pipeline = Pipeline (
            action: "literal",
            args: ["items" : argsItems],
            `let`: Document(dictionary: [Consts.pipelineCommandName :  letDocument])
        )
        
        return pipeline
    }
    
    private func handlePipelineResult(_ result: Any) {
        /// Parse the result
        if let outterResultArray = result as? BsonArray,
            !outterResultArray.isEmpty,
            let resultDocument = outterResultArray[0] as? Document,
            let resultArray = resultDocument[Consts.pipelineResultKey] as? BsonArray,
            !resultArray.isEmpty,
            let lastObject = resultArray[resultArray.count - 1] as? Document,
            let lastDistance = lastObject[Consts.distanceKey] as? Double {
            
            var restaurantsResult: [Restaurant] = []
            
            /// Save the current last restaurant's distance from the user for the next pagination fetch
            lastFetchDistance = lastDistance
            
            /// Reset the collection of restaurants to be excluded from the next fetch
            fetchObjectIdsToExclude = []
            
            for element in resultArray {
                
                /// The pipeline returns the restaurants as Document objects
                if let document = element as? Document {
                    
                    /// Create a Restaurant object from the document
                    let restaurant = Restaurant(document: document, mongoDBClient: MongoDBManager.shared.mongoClient)
                    restaurantsResult.append(restaurant)
                    
                    /// If this restaurant's distance is equal to the last distance fetched, add it to the collection of restaurants to be excluded from the next fetch
                    if let restaurantDistance = document[Consts.distanceKey] as? Double,
                        restaurantDistance == lastDistance,
                        let objectId = restaurant.objectId {
                        fetchObjectIdsToExclude.append(objectId)
                    }
                }
            }
            
            restaurants.append(contentsOf: restaurantsResult)
            restaurantTableView.reloadData()
            print("Loaded \(resultArray.count) restaurants")
        }
        
        noResultsLabel.isHidden = !restaurants.isEmpty
        restaurantTableView.isHidden = restaurants.isEmpty
    }
    
    private func criteria() -> Criteria? {
        /// Limits the query to the search text (if any)
        /// Limits the query to the filters applied (if any)
        /// Excludes already fetched restaurants with the same distance as we are trying to fetch now (if any)
        return searchCriteria() && filterCriteria() && excludeIdsCriteria()
    }
    
    /// A criteria based on the user's selected filters (if any)
    private func filterCriteria() -> Criteria? {
        guard filter != .none else {
            return nil
        }
        
        var criteria: Criteria?
        let attributesKey = Restaurant.attributesKey
        
        /// Append each of the selected filters to the criteria

        if filter.contains(.freeParking) {
            /// The filter is checked with a nested field inside the Restaurant model (inside its attributes field)
            criteria = criteria && .equals(field: "\(attributesKey).\(Attributes.hasParkingKey)", value: true)
        }
        
        if filter.contains(.vegan) {
            criteria = criteria && .equals(field: "\(attributesKey).\(Attributes.veganFriendlyKey)", value: true)
        }
        
        if filter.contains(.openWeekends) {
            criteria = criteria && .equals(field: "\(attributesKey).\(Attributes.openOnWeekendsKey)", value: true)
        }
        
        if filter.contains(.hasWifi) {
            criteria = criteria && .equals(field: "\(attributesKey).\(Attributes.hasWifiKey)", value: true)
        }
        
        return criteria
    }
    
    /// A criteria based on the user's selected search phrase (if any)
    private func searchCriteria() -> Criteria? {
        guard let searchedText = restaurantsSearchBar.text, !searchedText.isEmpty else {
            return nil
        }
        
        do {
            let regulareExpresstion = try NSRegularExpression(pattern: searchedText, options: .caseInsensitive)
            return .contains(field: Restaurant.nameKey, value: regulareExpresstion)
        }
        catch {
            print("error when creating regex: \(error)")
            return nil
        }
    }
    
    /// A criteria based on a list of restaurant id's to be excluded from the fetch, as explained above
    private func excludeIdsCriteria() -> Criteria? {
        var criteria: Criteria?

        if !fetchObjectIdsToExclude.isEmpty {
            for objectId in fetchObjectIdsToExclude {
                criteria = criteria && .notEqual(field: "_id", value: objectId)
            }
        }
        
        return criteria
    }
    
    /// Prefetch next batch of data when table is scrolled to a predefined number of entries from the end
    private func shouldLoadMore(atIndexPath indexPath: IndexPath) -> Bool {
        return indexPath.row == restaurants.count - Consts.fetchNextCountFromEnd
    }
    
    // MARK: - LocationManager
    
    private func initLocationManager(){
        locationManager.updateDelegate = self
        locationManager.authorizationDelegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdating()
    }
    
    // MARK: - LocationAuthorizationDelegate
    
    func authorizationStatusChanged() {
        if locationManager.isDenied() == true {
            locationManager.requestWhenInUseAuthorization()
            
            self.showErrorAlert(withDescription: "Please approve location services on your device")
        }
    }
    
    // MARK: - LocationUpdateDelegate
    
    func didFailUpdatingWithError(error: Error){
        print("Error updating location: \(error.localizedDescription)")
    }
    
    func didUpdateLoction() {
        /// Get the first location returned, and fetch the restaurants sorted by their distance from it
        if let location = locationManager.location(), userLocation == nil {
            userLocation = location
            locationManager.stopUpdating()
            fetchRestaurants()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: RestaurantTableViewCell.stringFromClass(), for: indexPath)
        let restaurant = restaurants[indexPath.row]

        if let restaurantCell = cell as? RestaurantTableViewCell,
            let locationCoordinate = restaurant.location?.coordinate,
            let myLocation = userLocation,
            let name = restaurant.name,
            let address = restaurant.address,
            let phone = restaurant.phone
        {
            let restaurantLocation = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            let rawDistance = myLocation.distance(from: restaurantLocation)
            let distance = Double(rawDistance / 1609.344)
            restaurantCell.set(restaurantName: name, distance: distance, address: address, phone: phone)
        } else {
            print("RestaurantListViewController Could not load restaurant cell - missing parameters")
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let singleRestaurantController = storyboard?.instantiateViewController(withIdentifier: SingleRestaurantViewController.stringFromClass()) as? SingleRestaurantViewController {
            let restaurant = restaurants[indexPath.row]
            singleRestaurantController.restaurant = restaurant
            singleRestaurantController.delegate = self
            navigationController?.pushViewController(singleRestaurantController, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Consts.cellHeight
    }
   
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        /// On each new cell display, check whether or not the next data page should be fetched
        if shouldLoadMore(atIndexPath: indexPath) {
            fetchRestaurants(paginated: true)
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        
        /// Clear the search text and reload the restaurants list
        searchBar.text = nil
        fetchRestaurants()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        
        /// Reload the restaurants list with the new search text
        fetchRestaurants()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    // MARK: - RestaurantFilterViewControllerDelegate
    
    func restaurantFilterViewControllerdidCancel(_ restaurantFilterViewController : RestaurantFilterViewController) {
        navigationController?.removeChildController(childController: restaurantFilterViewController)
    }
    
    func restaurantFilterViewControllerdidFinish(_ restaurantFilterViewController : RestaurantFilterViewController) {
        
        /// Update the selected filter, and refetch the restaurants
        filter = restaurantFilterViewController.currentFilter
        filerBarButton.tintColor = filter.isEmpty ? UIColor.white : UIColor(red: 251.0/255.0, green: 192.0/255.0, blue: 45.0/255.0, alpha: 1)
        
        navigationController?.removeChildController(childController: restaurantFilterViewController)
        fetchRestaurants()
    }
    
    // MARK: - SingleRestaurantViewControllerDelegate
    func singleRestaurantViewControllerDidUpdate(restaurant: Restaurant) {
        
        /// A restaurant was updated with a new average rating / rating count.
        /// Find it in the collection and replace it with the updated model
        if let indexOfRestaurant = restaurants.index(of: restaurant) {
            restaurants[indexOfRestaurant] = restaurant
        }
    }
    
    // MARK: - ReviewsFlowManagerDelegate
    
    func reviewsFlowManagerDidSave(review: Review) {
        showAlert(withTitle: nil, message: "Rating saved!")
    }
    
    func reviewsFlowManagerFailedToSaveReview() {
        showErrorAlert(withDescription: "Save rating failed")
    }
    
    func reviewsFlowManagerDidUpdateRestaurant() {
        
        /// The restaurant was updated with a new average rating & ratings count
        print("Restaurant updated with success")
    }

    
    // MARK: - Navigation
    
    private func navigateToMapController(){
        if let mapController = storyboard?.instantiateViewController(withIdentifier: MapViewController.stringFromClass()) as? MapViewController {
            mapController.set(title: "platespace", restaurants:restaurants, isTappable: true)
            navigationController?.pushViewController(mapController, animated: true)
        }
    }
    
    private func navigateToLoginPage() {
        navigationController?.setNavigationBarHidden(true, animated: true)
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - IBActions
    
    @IBAction func mapButtonPressed(_ sender: Any) {
        self.view.endEditing(true)
        navigateToMapController()
    }
    
    @IBAction func filerButtonPressed(_ sender: Any) {
        self.view.endEditing(true)
        if let filterController = storyboard?.instantiateViewController(withIdentifier: RestaurantFilterViewController.stringFromClass()) as? RestaurantFilterViewController {
            filterController.delegate = self
            filterController.currentFilter = filter
            
            navigationController?.addChildController(childController: filterController)
            
            filterController.animateView()
        }
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
       showAlert(
        withTitle: "Log out",
        message: "Are you sure you want to log out from platespace?",
        cancelButtonTitle: "Cancel",
        approveButtonTitle: "OK",
        approveActionHandler: { [weak self] (approveAction) in
        self?.logout()
       })
    }
    
    // MARK: - Logout
    
    private func logout() {
        
        showLoadingView(show: true)
        
        MongoDBManager.shared.stitchClient.logout().response { [weak self] result in
            
            self?.showLoadingView(show: false)
            
            switch result {
            case .success(_):
                
                /// Logout succeeded
                /// The response result value is an optional provider from whom we have logged out (returned in case we were indeed logged in)
                if let provider = MongoDBManager.shared.authProvider {
                    switch provider {
                    case is FacebookAuthProvider:
                        self?.logoutFacebook()
                    default:
                        self?.navigateToLoginPage()                        
                    }
                } else {
                    /// Logout was performed with a not logged in user, so no provider was returned
                    self?.navigateToLoginPage()
                }
            case .failure(let error):
                print("Error loging out: \(error.localizedDescription)")
                self?.showErrorAlert(withDescription: "Could not logout.")
            }
            
        }
    }
    
    private func logoutFacebook() {
        /// Logout from the database was performed.
        /// Logout also from Facebook
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        navigateToLoginPage()
    }
    
}
