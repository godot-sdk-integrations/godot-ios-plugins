# Godot iOS HealthKit plugin

## Methods

`bool is_available()`

- Check if HealthKit is available on device.

`Error create_health_store()`

- Creates a health store instance managed by this plugin.

`Error execute_statistics_query(String quantity_type_str, int start_date, int end_date, Callable on_query_success)`

- Starts a query to query health data. The callback will contain the health data.
