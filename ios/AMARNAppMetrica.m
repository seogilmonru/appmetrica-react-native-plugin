
#import "AMARNAppMetrica.h"
#import "AMARNAppMetricaUtils.h"
#import "AMARNStartupParamsUtils.h"
#import "AMARNUserProfileSerializer.h"
#import "AMARNExternalAttribution.h"
#import <AppMetricaCrashes/AppMetricaCrashes.h>
#import "AMARNExceptionSerializer.h"

@implementation AMARNAppMetrica

@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE(AppMetrica)

RCT_EXPORT_METHOD(activate:(NSDictionary *)configDict)
{
    [[AMAAppMetricaCrashes crashes] setConfiguration:[AMARNAppMetricaUtils crashConfigurationForDictionary:configDict]];
    [AMAAppMetrica activateWithConfiguration:[AMARNAppMetricaUtils configurationForDictionary:configDict]];
}

RCT_EXPORT_METHOD(getLibraryApiLevel)
{
    // It does nothing for iOS
}

RCT_EXPORT_METHOD(getLibraryVersion:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([AMAAppMetrica libraryVersion]);
}

RCT_EXPORT_METHOD(pauseSession)
{
    [AMAAppMetrica pauseSession];
}

RCT_EXPORT_METHOD(reportAppOpen:(NSString *)deeplink)
{
    [AMAAppMetrica trackOpeningURL:[NSURL URLWithString:deeplink]];
}

RCT_EXPORT_METHOD(reportError:(NSString *)identifier:(NSString *)message:(NSDictionary *)_reason) {
    [[[AMAAppMetricaCrashes crashes] pluginExtension] reportErrorWithIdentifier:identifier
                                                                        message:message
                                                                        details:amarn_exceptionForDictionary(_reason)
                                                                      onFailure:^(NSError *error) {
        NSLog(@"Failed to report error to AppMetrica: %@", [error localizedDescription]);
    }];
}

RCT_EXPORT_METHOD(reportEvent:(NSString *)eventName:(NSDictionary *)attributes)
{
    if (attributes == nil) {
        [AMAAppMetrica reportEvent:eventName onFailure:^(NSError *error) {
            NSLog(@"error: %@", [error localizedDescription]);
        }];
    } else {
        [AMAAppMetrica reportEvent:eventName parameters:attributes onFailure:^(NSError *error) {
            NSLog(@"error: %@", [error localizedDescription]);
        }];
    }
}

RCT_EXPORT_METHOD(requestStartupParams:(NSArray *)identifiers:(RCTResponseSenderBlock)listener)
{
    AMAIdentifiersCompletionBlock block = ^(NSDictionary<AMAStartupKey,id> * _Nullable identifiers, NSError * _Nullable error) {
        NSDictionary *result = [AMARNStartupParamsUtils toStrartupParamsResult:identifiers];
        NSString *errorStr = [AMARNStartupParamsUtils stringFromRequestStartupParamsError:error];
        listener(@[[self wrap:result], [self wrap:errorStr]]);
    };
    [AMAAppMetrica requestStartupIdentifiersWithKeys:[AMARNStartupParamsUtils toStartupKeys:identifiers] completionQueue:nil completionBlock:block];
}

RCT_EXPORT_METHOD(resumeSession)
{
    [AMAAppMetrica resumeSession];
}

RCT_EXPORT_METHOD(sendEventsBuffer)
{
    [AMAAppMetrica sendEventsBuffer];
}

RCT_EXPORT_METHOD(setLocation:(NSDictionary *)locationDict)
{
    AMAAppMetrica.customLocation = [AMARNAppMetricaUtils locationForDictionary:locationDict];
}

RCT_EXPORT_METHOD(setLocationTracking:(BOOL)enabled)
{
    AMAAppMetrica.locationTrackingEnabled = enabled;
}

RCT_EXPORT_METHOD(setDataSendingEnabled:(BOOL)enabled)
{
    [AMAAppMetrica setDataSendingEnabled:enabled];
}

RCT_EXPORT_METHOD(reportECommerce:(NSDictionary *)ecommerceDict)
{
    [AMAAppMetrica reportECommerce:[AMARNAppMetricaUtils ecommerceForDict:ecommerceDict] onFailure:nil];
}

RCT_EXPORT_METHOD(setUserProfileID:(NSString *)userProfileID)
{
    [AMAAppMetrica setUserProfileID:userProfileID];
}

RCT_EXPORT_METHOD(reportRevenue:(NSDictionary *)revenueDict)
{
    [AMAAppMetrica reportRevenue:[AMARNAppMetricaUtils revenueForDict:revenueDict] onFailure:nil];
}

RCT_EXPORT_METHOD(reportAdRevenue:(NSDictionary *)revenueDict)
{
    [AMAAppMetrica reportAdRevenue:[AMARNAppMetricaUtils adRevenueForDict:revenueDict] onFailure:nil];
}

RCT_EXPORT_METHOD(reportUserProfile:(NSDictionary *)userProfileDict)
{
    [AMAAppMetrica reportUserProfile:[AMARNAppMetricaUtils userProfileForDict:userProfileDict] onFailure:nil];
}

RCT_EXPORT_METHOD(putErrorEnvironmentValue:(NSString *)key:(NSString *)value)
{
    [[AMAAppMetricaCrashes crashes] setErrorEnvironmentValue:value forKey:key];
}

RCT_EXPORT_METHOD(reportExternalAttribution:(NSDictionary *)externalAttributionsDict)
{

    NSString *sourceStr = externalAttributionsDict[@"source"];
    AMAAttributionSource source = amarn_getExternalAttributionSource(sourceStr);
    if (source == nil) {
        NSLog(@"Failed to report external attribution to AppMetrica. Unknown source %@", sourceStr);
        return;
    }

    NSDictionary *value = externalAttributionsDict[@"value"];

    [AMAAppMetrica reportExternalAttribution:value source:source onFailure:^(NSError *error) {
        NSLog(@"Failed to report external attribution to AppMetrica: %@", [error localizedDescription]);
    }];
}

RCT_EXPORT_METHOD(reportErrorWithoutIdentifier:(NSString *)message:(NSDictionary *)error)
{
    AMAPluginErrorDetails *details = amarn_exceptionForDictionary(error);
    if (details.backtrace.count == 0) {
        [[[AMAAppMetricaCrashes crashes] pluginExtension] reportErrorWithIdentifier:@"Errors without stacktrace"
                                                                            message:message
                                                                            details:details
                                                                          onFailure:^(NSError *error) {
            NSLog(@"Failed to report error to AppMetrica: %@", [error localizedDescription]);
        }];
    } else {
        [[[AMAAppMetricaCrashes crashes] pluginExtension] reportError:details message:message onFailure:^(NSError *error) {
            NSLog(@"Failed to report error to AppMetrica: %@", [error localizedDescription]);
        }];
    }
}

RCT_EXPORT_METHOD(reportUnhandledException:(NSDictionary *)error)
{
    [[[AMAAppMetricaCrashes crashes] pluginExtension] reportUnhandledException:amarn_exceptionForDictionary(error)
                                                                     onFailure:^(NSError *error) {
        NSLog(@"Failed to report unhandled exception to AppMetrica: %@", [error localizedDescription]);
    }];
}

RCT_EXPORT_METHOD(putAppEnvironmentValue:(NSString *)key:(NSString *)value)
{
    [AMAAppMetrica setAppEnvironmentValue:value forKey:key];
}

RCT_EXPORT_METHOD(clearAppEnvironment)
{
    [AMAAppMetrica clearAppEnvironment];
}

RCT_EXPORT_METHOD(activateReporter:(NSDictionary *)configDict)
{
    [AMAAppMetrica activateReporterWithConfiguration:[AMARNAppMetricaUtils reporterConfigurationForDictionary:configDict]];
}

RCT_EXPORT_METHOD(touchReporter:(NSString *)apiKey)
{
    [AMAAppMetrica reporterForAPIKey:apiKey];
}

RCT_EXPORT_METHOD(getDeviceId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([AMAAppMetrica deviceID]);
}

RCT_EXPORT_METHOD(getUuid:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    resolve([AMAAppMetrica UUID]);
}

RCT_EXPORT_METHOD(requestDeferredDeeplink:(RCTResponseSenderBlock)onFailure:(RCTResponseSenderBlock)onSuccess)
{
    // It does nothing for iOS
}

RCT_EXPORT_METHOD(requestDeferredDeeplinkParameters:(RCTResponseSenderBlock)onFailure:(RCTResponseSenderBlock)onSuccess)
{
    // It does nothing for iOS
}

- (NSObject *)wrap:(NSObject *)value
{
    if (value == nil) {
        return [NSNull null];
    }
    return value;
}

@end
