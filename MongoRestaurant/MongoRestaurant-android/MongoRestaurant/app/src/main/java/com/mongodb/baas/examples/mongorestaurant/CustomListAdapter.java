package com.mongodb.stitch.examples.mongorestaurant;

import android.content.Context;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import org.bson.Document;

import java.util.List;

public class CustomListAdapter extends ArrayAdapter<Document> {

    private final Context _context;
    private final List<Document> docs;

    public CustomListAdapter(@NonNull final Context context,final List<Document> docs) {
        super(context, -1, docs);
        this._context = context;
        this.docs = docs;
    }

    @Override
    public View getView(int position, View convertView, @NonNull ViewGroup parent) {
        LayoutInflater inflater = (LayoutInflater) _context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        // The "row_layout.xml" consists of a Relative Layout with two
        // TextViews.
        View rowView = inflater.inflate(R.layout.row_layout, parent, false);

        TextView comment =  (TextView) rowView.findViewById(R.id.comment);
        TextView username = (TextView) rowView.findViewById(R.id.user);

        comment.setText(docs.get(position).get("comment").toString());

        username.setText(docs.get(position).get("user_id").toString());

        return rowView;
    }

}