#import "GNETextSearchTestResources.h"

@interface GNETextSearchTestResourcesSentinel : NSObject
@end

@implementation GNETextSearchTestResourcesSentinel
@end

static BOOL GNETextSearchBundleContainsFixtures(NSBundle *bundle)
{
    return [bundle pathForResource:@"words-beginning-with-A" ofType:@"txt"] != nil;
}

NSBundle *GNETextSearchTestResourcesBundle(void)
{
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSBundle *> *candidateBundles = @[
            [NSBundle bundleForClass:[GNETextSearchTestResourcesSentinel class]],
            [NSBundle mainBundle],
        ];

        for (NSBundle *candidate in candidateBundles) {
            if (GNETextSearchBundleContainsFixtures(candidate)) {
                bundle = candidate;
                return;
            }
        }

        NSMutableArray<NSURL *> *candidateURLs = [NSMutableArray array];
        NSString *bundleName = @"GNETextSearch_GNETextSearchCTests.bundle";
        for (NSBundle *candidate in candidateBundles) {
            NSURL *bundleURL = candidate.bundleURL;
            if (bundleURL == nil) { continue; }
            [candidateURLs addObject:[bundleURL URLByAppendingPathComponent:bundleName]];
            [candidateURLs addObject:[[bundleURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:bundleName]];
        }

        for (NSURL *candidateURL in candidateURLs) {
            NSBundle *candidate = [NSBundle bundleWithURL:candidateURL];
            if (candidate != nil && GNETextSearchBundleContainsFixtures(candidate)) {
                bundle = candidate;
                return;
            }
        }

        bundle = [NSBundle mainBundle];
    });

    return bundle;
}
