# PayPal Donation Setup Guide

This guide explains how to configure PayPal donations on your project websites.

## What You Need

**Minimum requirement:** PayPal Client ID only

- ✅ Client ID (from PayPal Developer Dashboard) - **REQUIRED**
- ❌ Merchant ID - Not needed
- ❌ Secret - Optional (only for backend verification)

## Files Involved

- **paypal-config.js** - Main configuration file (just your Client ID)
- **esp32-daikin.html** - ESP32 Daikin project page (includes donate button)
- **lefty.html** - Lefty project page (includes donate button)  
- **tabdocks.html** - TabDocks project page (includes donate button)

## Setup Steps

### Step 1: Get Your Client ID

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/dashboard/)
2. Log in with your PayPal account
3. On the left sidebar, click **Apps & Credentials**
4. Make sure you're viewing **Sandbox** (for testing) or **Live** (for production)
5. If you don't have an app yet, click **Create App**
6. Select your app from the list
7. Under **Client ID**, click **Show** and copy the full Client ID string

**Your Client ID looks like:**
```
ABCdef123GhIjKlMnOpQrStUvWxYz_4567890abcdefghijklmnopqrstuvwxyz...
```

### Step 2: Update Configuration File

Open `paypal-config.js` and enter your Client ID:

```javascript
const PayPalConfig = {
  clientId: "ABCdef123GhIjKlMnOpQrStUvWxYz_4567890abcdefghijklmnopqrstuvwxyz...",
  enabled: true,
  defaultAmounts: [5, 10, 25, 50],
  businessEmail: "your-email@paypal.com"
};
```

### Step 3: Test the Donate Button

1. Open each HTML page (esp32-daikin.html, lefty.html, tabdocks.html) in a browser
2. Scroll to the footer
3. You should see the PayPal donate button
4. Click it to test the donation flow

**If testing in Sandbox mode:**
- Use PayPal test buyer account: `sb-xxxxx@personal.example.com`
- Use test password: `Any1234`
- No real money is charged

### Step 4: Switch to Live Mode (Production)

When ready to accept real donations:

1. In [PayPal Developer Dashboard](https://developer.paypal.com/dashboard/), toggle to **Live** mode (top left)
2. Get your **Live Client ID** (follow Step 1 again but in Live mode)
3. In `paypal-config.js`, replace your Sandbox Client ID with the Live Client ID
4. Test with a small real donation ($0.01-$1.00) from your PayPal account

## Customization

### Change Donation Amount

Edit each HTML file and modify the `value` in the `createOrder` function:

```javascript
value: '10.00',  // Change this to your desired default amount
```

### Change Button Color

Edit each HTML file and modify the button style. Options available:
- `'gold'` - Gold (default PayPal color)
- `'blue'` - Blue
- `'silver'` - Silver
- `'white'` - White
- `'black'` - Black

Example:
```javascript
style: {
  shape: 'round',
  color: 'gold',  // Change this
  layout: 'vertical',
  label: 'donate'
}
```

### Add Multiple Donation Amounts

You can create multiple buttons for different amounts by duplicating the PayPal initialization code and creating different containers.

## Environment Variables (Optional)

For enhanced security, you can use environment variables:

```javascript
const PayPalConfig = {
  clientId: process.env.PAYPAL_CLIENT_ID || "YOUR_PAYPAL_CLIENT_ID_HERE",
  enabled: process.env.PAYPAL_ENABLED !== 'false',
  defaultAmounts: [5, 10, 25, 50],
  businessEmail: process.env.PAYPAL_EMAIL || "your-email@paypal.com"
};
```

## Troubleshooting

### Button Not Appearing

- Check that `PayPalConfig.clientId` is set correctly (not the placeholder text)
- Verify that `PayPalConfig.enabled` is `true`
- Check browser console for JavaScript errors (F12 → Console)
- Ensure you're using the correct Client ID (Sandbox vs Live match)

### "Cannot connect to PayPal"

- Ensure you're using the correct Client ID for your environment (Sandbox vs Live)
- Check your internet connection
- Verify PayPal servers are accessible
- Check that the Client ID hasn't been revoked

### Transaction Failed

- In Sandbox mode, only use official test buyer credentials
- Ensure sufficient test account balance in Sandbox
- Check PayPal account for transaction limits or restrictions
- Verify the Client ID hasn't expired

### "Unable to load release metadata" but Button Works

This is unrelated to PayPal donations - it means the HTML page couldn't load release metadata files from the downloads/ directory.

## Security Notes

- Never commit real PayPal Client IDs to public repositories
- Use environment variables for production deployments
- Regularly review PayPal transaction reports
- Keep your Secret key (if using backend verification) completely private
- Use HTTPS in production (not required for local testing)

## Testing Checklist

- [ ] Client ID entered in `paypal-config.js`
- [ ] `enabled: true` in PayPal config
- [ ] Donate button visible in footer when page loads
- [ ] Button clickable and opens PayPal flow
- [ ] In Sandbox: Can complete donation with test credentials
- [ ] Button colors/styles match page theme
- [ ] Works on mobile/responsive view
- [ ] Ready to switch to Live Client ID and go live

## Support

For PayPal issues:
- [PayPal Developer Documentation](https://developer.paypal.com/docs/)
- [PayPal Help Center](https://www.paypal.com/support)
- [PayPal Checkout SDK](https://developer.paypal.com/docs/checkout/integrate/)

For button implementation issues:
- Check browser console for error messages
- Review the [PayPal Checkout JavaScript SDK](https://developer.paypal.com/sdk/js/)
- Test in Sandbox mode first before going Live
