module.exports = async (req, res) => {
  // Must be served without extension and with correct content-type
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');

  const teamId = process.env.APPLE_TEAM_ID;
  const bundleId = process.env.IOS_BUNDLE_ID;

  if (!teamId || !bundleId) {
    return res.status(400).json({
      error: 'Missing APPLE_TEAM_ID or IOS_BUNDLE_ID',
      restore: [
        'In Vercel → Project → Settings → Environment Variables, add:',
        'APPLE_TEAM_ID = Your Apple Developer Team ID (e.g., ABCDE12345)',
        'IOS_BUNDLE_ID = Your iOS app bundle identifier (e.g., com.yourcompany.MovieDrop)',
        'Redeploy, then iOS Universal Links will resolve to the app.'
      ]
    });
  }

  const appID = `${teamId}.${bundleId}`;
  const payload = {
    applinks: {
      apps: [],
      details: [
        {
          appID,
          // Only open these paths in the app
          paths: [
            '/m/*'
          ]
        }
      ]
    }
  };

  return res.status(200).send(JSON.stringify(payload));
};


