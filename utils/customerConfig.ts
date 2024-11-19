// utils/customerConfig.ts

export interface CustomerConfig {
    cognitoDomain: string;
    clientId: string;
    userPoolId: string;
    region: string;
    redirectUri: string;
}

export const customerConfigs: { [key: string]: CustomerConfig } = {
    mt1: {
        cognitoDomain: 'reva-auth.auth.us-east-1.amazoncognito.com',
        clientId: '78kpitfq2dco5koudokohp33n4',
        userPoolId: 'us-east-1_9lP996gFI',
        region: 'us-east-1',
        redirectUri: 'https://mt1.ea.reva.ai/callback',
    },
    mt2: {
        cognitoDomain: 'reva-auth-test9.auth.us-east-1.amazoncognito.com',
        clientId: '7o20umpaan13mibjuuiod0407n',
        userPoolId: 'us-east-1_YEce83Zit',
        region: 'us-east-1',
        redirectUri: 'https://mt2.ea.reva.ai/callback',
    },
    mt3: {
        cognitoDomain: 'https://reva-auth-test6.auth.us-east-1.amazoncognito.com',
        clientId: '476f4hlm7kfm60ic8smehrp7vl',
        userPoolId: 'us-east-1_B7VSw0fEc',
        region: 'us-east-1',
        redirectUri: 'https://mt3.ea.reva.ai/callback',
    },
    mt4: {
        cognitoDomain: 'reva-auth-test5.auth.us-east-1.amazoncognito.com',
        clientId: 'd98usmnlf9979tci79on5g8nj',
        userPoolId: 'us-east-1_Yojn9QwZS',
        region: 'us-east-1',
        redirectUri: 'https://mt4.ea.reva.ai/callback',
    },
};
