package com.mongodb.stitch.sdk.examples.todo;

import android.content.Context;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.TextView;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.mongodb.stitch.android.services.mongodb.MongoClient;

import org.bson.Document;
import org.bson.types.ObjectId;

import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class TodoListAdapter extends ArrayAdapter<TodoItem> {

    private final MongoClient.Collection _itemSource;

    // Store the expected state of the items based off the users intentions. This is to handle this
    // series of events:
    // Check Item Request Begin - Item in state X
    // Refresh List - Item in state Y, View is refreshed
    // Check Item Request End - Item in State X
    // Refresh List - Item in state X, View is refreshed
    //
    // In this example app, these updates happen on the UI thread,
    // so no synchronization is necessary.
    private final Map<ObjectId, Boolean> _itemState;

    public TodoListAdapter(
            final Context context,
            final int resource,
            final List<TodoItem> items,
            final MongoClient.Collection itemSource
    ) {
        super(context, resource, items);
        _itemSource = itemSource;
        _itemState = new HashMap<>();
    }

    @NonNull
    @Override
    public View getView(
            final int position,
            final View convertView,
            @NonNull final ViewGroup ignored){

        final View row;
        if(convertView == null) {
            final LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            row = inflater.inflate(R.layout.todo_item, null);
        } else  {
            // Reuse past view
            row = convertView;
        }

        final TodoItem item = this.getItem(position);

        // Hydrate data/event handlers
        ((TextView) row.findViewById(R.id.text)).setText(item.getText());

        final CheckBox checkBox = (CheckBox) row.findViewById(R.id.checkBox);
        checkBox.setOnCheckedChangeListener(null);

        if (_itemState.containsKey(item.getId())) {
            checkBox.setChecked(_itemState.get(item.getId()));
        } else {
            checkBox.setChecked(item.getChecked());
        }

        checkBox.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean b) {
                final Document query = new Document();
                query.put("_id", item.getId());

                final Document update = new Document();
                final Document set = new Document();
                set.put("checked", b);
                update.put("$set", set);

                _itemState.put(item.getId(), b);
                _itemSource.updateOne(query, update).addOnCompleteListener(new OnCompleteListener<Document>() {
                    @Override
                    public void onComplete(@NonNull final Task<Document> task) {

                        // Our intent may no longer be valid, so clear the state
                        _itemState.remove(item.getId());
                    }
                });
            }
        });

        return row;
    }
}
