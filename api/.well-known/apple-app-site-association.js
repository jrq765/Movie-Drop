module.exports = async function handler(req, res) {
  const aasa = {
    "applinks": {
      "apps": [],
      "details": [
        {
          "appID": "TEAM_ID.com.moviedrop.app",
          "paths": [
            "/m/*",
            "/movie/*"
          ]
        }
      ]
    }
  };

  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.status(200).json(aasa);
};