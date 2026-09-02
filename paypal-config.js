/**
 * PayPal Configuration
 * Configure your PayPal account details here
 * 
 * REQUIRED: Client ID only
 * Get from: https://developer.paypal.com/dashboard/
 * (Apps & Credentials → Sandbox/Live → Client ID)
 */

const PayPalConfig = {
  // Your PayPal Client ID (REQUIRED for donation buttons)
  // Get from: https://developer.paypal.com/dashboard/
  // Under: Apps & Credentials → Select your app → Show Client ID
  clientId: "AYqOe9_U7fxba2rDX_41H4NZnJC2dwRVftiNSWXW2--E_EkLQatDyUETF2rbwdsWCWmeg3prcexh-0Ki",

  // Enable/disable PayPal buttons on pages
  enabled: true,

  // Default donation amounts (in USD)
  defaultAmounts: [5, 10, 25, 50],

  // Your PayPal email (optional, for reference)
  businessEmail: "boschiotto4@gmail.com"
};
