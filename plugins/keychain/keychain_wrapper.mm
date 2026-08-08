#import "keychain_wrapper.h"
#import <Security/Security.h>

@implementation KeychainWrapper

+ (NSMutableDictionary *)queryForKey:(NSString *)key {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: key,
        (__bridge id)kSecAttrService: [[NSBundle mainBundle] bundleIdentifier]
    } mutableCopy];
}

+ (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    NSMutableDictionary *query = [self queryForKey:key];
    SecItemDelete((__bridge CFDictionaryRef)query);
    query[(__bridge id)kSecValueData] = [value dataUsingEncoding:NSUTF8StringEncoding];
    return SecItemAdd((__bridge CFDictionaryRef)query, NULL) == errSecSuccess;
}

+ (NSString *)getStringForKey:(NSString *)key {
    NSMutableDictionary *query = [self queryForKey:key];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result) == errSecSuccess) {
        NSData *data = (__bridge_transfer NSData *)result;
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (BOOL)deleteStringForKey:(NSString *)key {
    NSMutableDictionary *query = [self queryForKey:key];
    return SecItemDelete((__bridge CFDictionaryRef)query) == errSecSuccess;
}

@end
