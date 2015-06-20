_ = require 'underscore'

request = require 'request'
async = require 'async'
qs = require 'querystring'

helpers = require './helpers'


auditClosed = (req, res, next) ->
  return unless helpers.validateEvent 'issues', req, res

  unless helpers.verifySignature req.body, req.headers['x-hub-signature']
    console.log 'Signatures invalid aborting.'
    res.status(403).end()
    return

  # Only deal with issues tagged 'audit' that were closed
  unless 'audit' in (_.map req.body.issue.labels, (label) -> label.name)
    console.log 'Not an audit issue.'
    res.end()
  unless req.body.action == 'closed'
    console.log 'The action performed was not "closed".'
    res.end()

  # Build issue and comments URL
  repo = req.body.repository.full_name
  number = req.body.issue.number
  q = { access_token: process.env.GITHUB_ACCESS_TOKEN }
  issueUri = "https://api.github.com/repos/#{repo}/issues/#{number}"
  commentsUri = "#{issue_uri}/comments?#{qs.stringify(q)}"

  # TODO: Get linked issues by parsing first comment

  # TODO: Close each linked issue


module.exports = auditClosed
