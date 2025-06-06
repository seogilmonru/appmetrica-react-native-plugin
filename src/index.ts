import { Linking, NativeModules, Platform } from 'react-native';
import type { ECommerceEvent } from './ecommerce';
import type { AdRevenue, Revenue } from './revenue';
import type { UserProfile } from './userProfile';
import type { ExternalAttribution } from './externalAttribution';
import { normalizeAdRevenue } from './utils';
import { AppMetricaError } from './error';
import { Reporter, type IReporter, type ReporterConfig } from './reporter';
import type {
  DeferredDeeplinkListener,
  DeferredDeeplinkParametersListener,
} from './deferredDeeplink';

const LINKING_ERROR =
  `The package '@appmetrica/react-native-analytics' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const AppMetricaNative = NativeModules.AppMetrica
  ? NativeModules.AppMetrica
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

var activated = false;

function appOpenTracking() {
  const getUrlAsync = async () => {
    const initialUrl = await Linking.getInitialURL();
    if (initialUrl != null) {
      AppMetricaNative.reportAppOpen(initialUrl);
    }
  };
  const callback = (event: { url: string }) => {
    AppMetricaNative.reportAppOpen(event.url);
  };
  getUrlAsync();
  Linking.addEventListener('url', callback);
}

export type AppMetricaConfig = {
  apiKey: string;
  appVersion?: string;
  crashReporting?: boolean;
  firstActivationAsUpdate?: boolean;
  location?: Location;
  locationTracking?: boolean;
  logs?: boolean;
  sessionTimeout?: number;
  statisticsSending?: boolean;
  preloadInfo?: PreloadInfo;
  maxReportsInDatabaseCount?: number;
  nativeCrashReporting?: boolean; // Android only
  activationAsSessionStart?: boolean; // iOS only
  sessionsAutoTracking?: boolean; // iOS only
  appOpenTrackingEnabled?: boolean;
  userProfileID?: string;

  errorEnvironment?: Record<string, string | undefined>;
  appEnvironment?: Record<string, string | undefined>;
  maxReportsCount?: number;
  dispatchPeriodSeconds?: number;
};

export type PreloadInfo = {
  trackingId: string;
  additionalInfo?: Record<string, string>;
};

export type Location = {
  latitude: number;
  longitude: number;
  altitude?: number;
  accuracy?: number;
  course?: number;
  speed?: number;
  timestamp?: number;
};

export type StartupParamsReason = 'UNKNOWN' | 'NETWORK' | 'INVALID_RESPONSE';

export type StartupParams = {
  deviceIdHash?: string;
  deviceId?: string;
  uuid?: string;
};

export type StartupParamsCallback = (
  params?: StartupParams,
  reason?: StartupParamsReason
) => void;

export const DEVICE_ID_HASH_KEY = 'appmetrica_device_id_hash';
export const DEVICE_ID_KEY = 'appmetrica_device_id';
export const UUID_KEY = 'appmetrica_uuid';

export * from './ecommerce';
export * from './revenue';
export * from './userProfile';
export * from './externalAttribution';
export type { IReporter, ReporterConfig } from './reporter';
export * from './deferredDeeplink';

export default class AppMetrica {

  private static reporters: Map<string, Reporter> = new Map();

  static activate(config: AppMetricaConfig) {
    if (!activated) {
      AppMetricaNative.activate(config);
      if (config.appOpenTrackingEnabled !== false) {
        appOpenTracking();
      }
      activated = true;
    }
  }

  // Android only
  static async getLibraryApiLevel(): Promise<number> {
    return AppMetricaNative.getLibraryApiLevel();
  }

  static async getLibraryVersion(): Promise<string> {
    return AppMetricaNative.getLibraryVersion();
  }

  static pauseSession() {
    AppMetricaNative.pauseSession();
  }

  static reportAppOpen(deeplink?: string) {
    AppMetricaNative.reportAppOpen(deeplink);
  }

  static reportError(
    identifier: string,
    message?: string,
    _reason?: Error | Object
  ) {
    AppMetricaNative.reportError(
      identifier,
      message,
      _reason instanceof Error ? AppMetricaError.withError(_reason) : AppMetricaError.withObject(_reason)
    );
  }

  static reportUnhandledException(error: Error) {
    AppMetricaNative.reportUnhandledException(AppMetricaError.withError(error));
  }

  static reportErrorWithoutIdentifier(message: string | undefined, error: Error) {
    AppMetricaNative.reportErrorWithoutIdentifier(message, AppMetricaError.withError(error));
  }

  static reportEvent(eventName: string, attributes?: Record<string, any>) {
    AppMetricaNative.reportEvent(eventName, attributes);
  }

  static requestStartupParams(
    listener: StartupParamsCallback,
    identifiers: Array<string>
  ) {
    AppMetricaNative.requestStartupParams(identifiers, listener);
  }

  static resumeSession() {
    AppMetricaNative.resumeSession();
  }

  static sendEventsBuffer() {
    AppMetricaNative.sendEventsBuffer();
  }

  static setLocation(location?: Location) {
    AppMetricaNative.setLocation(location);
  }

  static setLocationTracking(enabled: boolean) {
    AppMetricaNative.setLocationTracking(enabled);
  }

  static setDataSendingEnabled(enabled: boolean) {
    AppMetricaNative.setDataSendingEnabled(enabled);
  }

  static setUserProfileID(userProfileID?: string) {
    AppMetricaNative.setUserProfileID(userProfileID);
  }

  static reportECommerce(event: ECommerceEvent) {
    AppMetricaNative.reportECommerce(event);
  }

  static reportRevenue(revenue: Revenue) {
    AppMetricaNative.reportRevenue(revenue);
  }

  static reportAdRevenue(adRevenue: AdRevenue) {
    AppMetricaNative.reportAdRevenue(normalizeAdRevenue(adRevenue));
  }

  static reportUserProfile(userProfile: UserProfile) {
    AppMetricaNative.reportUserProfile(userProfile);
  }

  static putErrorEnvironmentValue(key: string, value?: string) {
    AppMetricaNative.putErrorEnvironmentValue(key, value);
  }

  static reportExternalAttribution(attribution: ExternalAttribution) {
    AppMetricaNative.reportExternalAttribution(attribution);
  }

  static putAppEnvironmentValue(key: string, value?: string) {
    AppMetricaNative.putAppEnvironmentValue(key, value);
  }

  static clearAppEnvironment() {
    AppMetricaNative.clearAppEnvironment();
  }

  static getReporter(apiKey: string): IReporter {
    if (AppMetrica.reporters.has(apiKey)) {
      return AppMetrica.reporters.get(apiKey)!;
    } else {
      AppMetricaNative.touchReporter(apiKey);
      const reporter = new Reporter(apiKey);
      AppMetrica.reporters.set(apiKey, reporter);
      return reporter;
    }
  }

  static activateReporter(config: ReporterConfig) {
    AppMetricaNative.activateReporter(config);
  }

  static getDeviceId(): Promise<string | null> {
    return AppMetricaNative.getDeviceId();
  }

  static getUuid(): Promise<string | null> {
    return AppMetricaNative.getUuid();
  }

  static requestDeferredDeeplink(listener: DeferredDeeplinkListener) {
    AppMetricaNative.requestDeferredDeeplink(
      listener.onFailure,
      listener.onSuccess
    );
  }

  static requestDeferredDeeplinkParameters(
    listener: DeferredDeeplinkParametersListener
  ) {
    AppMetricaNative.requestDeferredDeeplinkParameters(
      listener.onFailure,
      listener.onSuccess
    );
  }
}
