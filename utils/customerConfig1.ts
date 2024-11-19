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
    reva: {
        cognitoDomain: 'reva-auth.auth.us-east-1.amazoncognito.com',
        clientId: '78kpitfq2dco5koudokohp33n4',
        clientSecret: '5lv29uq8rb21mo2scf2n768684rho5k8qal0sfc46ugp21gf58s',
        userPoolId: 'us-east-1_9lP996gFI',
        region: 'us-east-1',
        redirectUri: 'http://localhost:3000/callback',
        logoutUri: 'http://localhost:3000'
    },
    mt1: {
        cognitoDomain: 'reva-auth-client36.auth.us-east-1.amazoncognito.com',
        clientId: '47j3nqkhp8dcktnaonr30mav2k',
        clientSecret: '1rrur6n50etb5r57qtmsdtp6e1a9kiib5b1ops6c0uitoi8vhit4',
        userPoolId: 'us-east-1_8rnj3sLV2',
        region: 'us-east-1',
        redirectUri: 'https://mt1.ea.reva.ai/callback',
        logoutUri: 'https://mt1.ea.reva.ai'
    },
    mt2: {
        cognitoDomain: 'reva-auth-test9.auth.us-east-1.amazoncognito.com',
        clientId: '7o20umpaan13mibjuuiod0407n',
        clientSecret: 'rvim138u91hu7sqokvc036d91gnhjmr163g5pm7rkelu2mntf38',
        userPoolId: 'us-east-1_YEce83Zit',
        region: 'us-east-1',
        redirectUri: 'https://mt2.ea.reva.ai/callback',
        logoutUri: 'https://mt2.ea.reva.ai'
    },
    mt3: {
        cognitoDomain: 'reva-auth-test6.auth.us-east-1.amazoncognito.com',
        clientId: '476f4hlm7kfm60ic8smehrp7vl',
        clientSecret: '68p97cturscub2a7mhgutlt8b8d7fv8q5rg4elde9utals54ise',
        userPoolId: 'us-east-1_B7VSw0fEc',
        region: 'us-east-1',
        redirectUri: 'https://mt3.ea.reva.ai/callback',
        logoutUri: 'https://mt3.ea.reva.ai'
    },
    mt4: {
        cognitoDomain: 'reva-auth-test5.auth.us-east-1.amazoncognito.com',
        clientId: 'd98usmnlf9979tci79on5g8nj',
        clientSecret: 'fophmnveiidvksj6g11ccl9llcgc2jkkrrpcrnh222cf8gc1eke',
        userPoolId: 'us-east-1_Yojn9QwZS',
        region: 'us-east-1',
        redirectUri: 'https://mt4.ea.reva.ai/callback',
        logoutUri: 'https://mt4.ea.reva.ai'
    },
};