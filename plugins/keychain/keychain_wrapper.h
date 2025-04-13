#import <Foundation/Foundation.h>

@interface KeychainWrapper : NSObject

+ (BOOL)setString:(NSString *)value forKey:(NSString *)key;
+ (NSString *)getStringForKey:(NSString *)key;
+ (BOOL)deleteStringForKey:(NSString *)key;

@end
