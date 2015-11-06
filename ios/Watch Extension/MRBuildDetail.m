#import "BridgingHeader.h"

NSString *buildDate() {
    NSMutableString *result = [NSMutableString stringWithString:@__DATE__];
    [result appendString:@" "];
    [result appendString:@__TIME__];
    return result;
}
 