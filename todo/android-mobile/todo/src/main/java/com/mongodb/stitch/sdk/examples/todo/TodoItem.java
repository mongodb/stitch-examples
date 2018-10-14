package com.mongodb.stitch.sdk.examples.todo;

import org.bson.Document;
import org.bson.types.ObjectId;

public class TodoItem {
    private final ObjectId _id;
    private final String _text;
    private final boolean _checked;

    public TodoItem(final Document document) {
        _id = document.getObjectId("_id");
        _text = document.getString("text");
        if (document.containsKey("checked")) {
            _checked = document.getBoolean("checked");
        } else {
            _checked = false;
        }
    }

    public ObjectId getId() {
        return _id;
    }

    public String getText() {
        return _text;
    }

    public boolean getChecked() {
        return _checked;
    }
}
