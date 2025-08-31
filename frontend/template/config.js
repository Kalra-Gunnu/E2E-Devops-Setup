// Configuration file for API endpoints and other settings
window.APP_CONFIG = {
    // API Base URLs - these will be replaced by environment variables
    PROJECT_SERVICE_URL: '${PROJECT_SERVICE_URL}',
    PAYMENT_SERVICE_URL: '${PAYMENT_SERVICE_URL}',
    USER_SERVICE_URL: '${USER_SERVICE_URL}',
    
    // Razorpay configuration
    RAZORPAY_KEY: '${RAZORPAY_KEY}',
    
    // Other configurable settings
    COMPANY_NAME: '${COMPANY_NAME}',
    CURRENCY: '${CURRENCY}'
};

// Helper function to get API URL
window.getApiUrl = function(service, endpoint) {
    const baseUrl = window.APP_CONFIG[service + '_SERVICE_URL'];
    if (!baseUrl) {
        console.error(`Service URL not configured for: ${service}`);
        return null;
    }
    return `${baseUrl}${endpoint}`;
};

// Helper function to get config value
window.getConfig = function(key) {
    return window.APP_CONFIG[key];
};
