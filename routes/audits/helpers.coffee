helpers = {}

# event needs to be 'ping' or `event`
helpers.validateEvent = (event, req, res) ->
  # ping event
  if req.headers['x-github-event'] == 'ping'
    console.log "ping event received.\n#{req.body.zen}"
    res.status(204).end()
    return false

  # only deal with issues events
  if req.headers['x-github-event'] != event
    res.status(400).end()
    return false

  return true


# Compute hash of payload to determine validity of response
verifySignature = (payload, expected) ->
  # signature invalid if one is present but the other isn't
  return false if expected? != process.env.WEBHOOK_SECRET?
  # only verify if both are present
  return true unless expected?

  actual = crypto
    .createHmac 'sha1', process.env.WEBHOOK_SECRET
    .update JSON.stringify(payload)
    .digest 'hex'

  return expected == "sha1=#{actual}"


module.exports = helpers
