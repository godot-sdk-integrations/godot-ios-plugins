# Godot iOS InAppStore plugin

## Methods

`request_product_info(Dictionary products_dictionary)` - Loads the unique identifiers for your in-app products in order to retrieve products information. Generates new event with `product_info` type.  
`restore_purchases()` - Asks App Store payment queue to restore previously completed purchases. Generates new event with `restore` type.  
`purchase(Dictionary product_dictionary)` - Adds a product payment request to the App Store payment queue. Generates new event with `purchase` type.  
`set_auto_finish_transaction(bool flag)` - Sets a value responsible for enabling automatic transaction finishing.  
`finish_transaction(String product_id)` - Notifies the App Store that the app finished processing the transaction.  

## Properties

## Events reporting

`get_pending_event_count()` - Returns number of events pending from plugin to be processed.  
`pop_pending_event()` - Returns first unprocessed plugin event.  