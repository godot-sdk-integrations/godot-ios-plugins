# Godot iOS HealthKit plugin

## Methods

`bool is_available()` - Check if HealthKit is available on device.
`Error create_health_store()` - Creates a health store instance managed by this plugin.
`Error query_health_data(long start_date, long end_date, String data_type, health_data_callback callback)` - Starts a query to query health data. The callback will contain the health data.
