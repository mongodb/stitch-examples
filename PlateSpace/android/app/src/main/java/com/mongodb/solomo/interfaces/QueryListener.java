package com.mongodb.solomo.interfaces;

/**
 * Interface for queries on MongoDB
 */

public interface QueryListener<T>
{
    void onSuccess(T result);
    void onError(Exception e);
}
