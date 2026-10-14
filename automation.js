const { chromium, firefox, webkit } = require('playwright');
const path = require('path');
const fs = require('fs');

async function runAutomation() {
  const browserType = (process.env.BROWSER || 'firefox').toLowerCase();
  const isHeadless = process.env.HEADLESS === 'true';
  const slowMo = parseInt(process.env.SLOWMO || (isHeadless ? '0' : '100'), 10);
  const targetUrl = process.env.TARGET_URL || 'https://playwright.dev';

  console.log(`===============================================`);
  console.log(`Starting Playwright Automation`);
  console.log(`Browser  : ${browserType}`);
  console.log(`Headless : ${isHeadless}`);
  console.log(`SlowMo   : ${slowMo}ms`);
  console.log(`Target   : ${targetUrl}`);
  console.log(`===============================================`);

  const browserEngines = { chromium, firefox, webkit };
  const engine = browserEngines[browserType];

  if (!engine) {
    throw new Error(`Unsupported browser: ${browserType}. Supported options: chromium, firefox, webkit`);
  }

  const browser = await engine.launch({
    headless: isHeadless,
    slowMo: slowMo
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 }
  });

  const page = await context.newPage();

  try {
    console.log(`Navigating to ${targetUrl}...`);
    await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });

    const title = await page.title();
    console.log(`Page loaded successfully!`);
    console.log(`Title: "${title}"`);

    // Example interaction: Click on the "Get started" button if available
    const getStartedLink = page.locator('text=Get started').first();
    if (await getStartedLink.isVisible({ timeout: 3000 }).catch(() => false)) {
      console.log(`Found "Get started" link. Clicking...`);
      await getStartedLink.click();
      await page.waitForTimeout(1000);
      console.log(`Current URL after click: ${page.url()}`);
    }

    // Ensure output directory exists
    const outputDir = path.join(__dirname, 'output');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    const screenshotPath = path.join(outputDir, 'screenshot.png');
    await page.screenshot({ path: screenshotPath, fullPage: false });
    console.log(`Screenshot saved to ${screenshotPath}`);

    // If running in GUI mode, pause briefly so the user can see the result
    if (!isHeadless) {
      console.log(`Keeping browser visible for 3 seconds before closing...`);
      await page.waitForTimeout(3000);
    }
  } catch (error) {
    console.error('Error during automation:', error);
    throw error;
  } finally {
    console.log(`Closing browser...`);
    await browser.close();
    console.log(`Done.`);
  }
}

runAutomation().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
