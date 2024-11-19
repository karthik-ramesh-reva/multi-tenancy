// utils/customerConfig.ts

export interface CustomerConfig {
    cognitoDomain: string;
    clientId: string;
    clientSecret: string;
    userPoolId: string;
    region: string;
    redirectUri: string;
    logoutUri: string;
}

export const customerConfigs: { [key: string]: CustomerConfig } = {
    // Add your customer configurations here
};
