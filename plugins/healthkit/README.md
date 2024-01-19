# Godot iOS HealthKit plugin

## Enum

Type: `AuthorizationStatus`  
Values: `AUTHORIZATION_STATUS_NOT_DETERMINED`, `AUTHORIZATION_STATUS_DENIED`, `AUTHORIZATION_STATUS_AUTHORIZED`

Type: `ObjectType`  
Values: `OBJECT_TYPE_UNKNOWN`, `OBJECT_TYPE_QUANTITY_TYPE_STEP_COUNT`, `OBJECT_TYPE_QUANTITY_TYPE_ACTIVE_ENERY_BURNED`

Type: `QuantityType`  
Values: `QUANTITY_TYPE_UNKNOWN`, `QUANTITY_TYPE_STEP_COUNT`, `QUANTITY_TYPE_ACTIVE_ENERY_BURNED`

## Methods

`bool is_health_data_available()`

- Check if HealthKit is available on device.

`Error request_authorization(Vector<int> to_share, Vector<int> to_read)`

- Requests authorization to share and read the given object types.

`SharingAuthorizationStatus authorization_status_for_type(ObjectType object_type)`

- Used to determine if the user is permitted to share the given object type. Should be called before actually sharing.

`Error execute_statistics_query(QuantityType quantity_type, int start_date, int end_date)`

- Starts a query to query health data of the given quantity type.

## Signals

`authorization_complete(int object_type, int status)`

- Called when the authorization has completed.

`statistics_query_completed(int quantity_type, float value)`

- Called when the statistics query has completed for the given quantity type.

`statistics_query_failed(int quantity_type, int error_code)`

- Called when the statistics query has failed for the given quantity type.
