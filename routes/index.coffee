_ = require 'underscore'

express = require 'express'
request = require 'request'
async = require 'async'
qs = require 'querystring'

router = express.Router()

# GET home page.
router.get '/', (req, res, next) ->
  res.render 'index'


# Redirect to GitHub login page
router.get '/login', (req, res, next) ->
  uri = 'https://github.com/login/oauth/authorize'
  params =
    scope: 'repo'
    client_id: process.env.GITHUB_CLIENT_ID

  res.redirect "#{uri}?#{qs.stringify params}"


# Acquire access token
router.get '/callback', (req, res, next) ->
  session_code = req.query.code

  uri = 'https://github.com/login/oauth/access_token'

  body =
    client_id: process.env.GITHUB_CLIENT_ID
    client_secret: process.env.GITHUB_CLIENT_SECRET
    code: session_code
    accept: 'application/json'

  callback = (err, _res, body) ->
    # TODO check that user has given us sufficent scope
    if not err
      console.log body
      res.render 'index', { access_token: body.access_token }

  request.post {uri: uri, body: body, json: true}, callback


router.post '/postreceive', require('./postreceive')

module.exports = router
