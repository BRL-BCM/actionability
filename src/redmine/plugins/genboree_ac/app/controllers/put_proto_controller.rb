class PutProtoController < ApplicationController
  include GenericHelpers::BeforeFiltersHelper
  include ProjectHelpers::BeforeFiltersHelper
  include PluginHelpers::BeforeFiltersHelper
  include KbHelpers::KbProjectHelper

  unloadable

  before_filter :find_project, :authorize, :kbProjectSettings

  # API-type controllers don't need a login session. But if so auth info will have to be
  #   provided somehow. API Key or HTTP Basic Authentication, etc.
  skip_before_filter :check_if_login_required
  # Skip the anti-forgery CSRF token checking--which are good--for particular methods
  skip_before_filter :verify_authenticity_token, :only => [ :putGrp ]

  accept_api_auth :putGrp

  # Can put ".json" on the end to get back JSON response instead of default html.
  # * Even for 403 Forbidden, although Rails won't give a payload for 403 response.
  # * Unless you're going to arrange HTTP Basic Authentication in your API request,
  #   you'll probably want to supply a valid API key (via the 'key' query string param)
  #   if using this outside of the UI, where you have no session.
  respond_to :json

  PLUGIN_SETTINGS_MODEL_CLASS = GenboreeAc

  def putGrp()
    grpName = params['grpName']
    rsrcPath  = "/REST/v1/grp/{grp}"
    targetHost = @gbHost
    fieldMap = { :grp => grpName }
    payload = {
      'data' => {
        'name' => grpName,
        'description' => 'Some new desc'
      }
    }
    $stderr.debugPuts(__FILE__, __method__, 'PROTO ASYNC PUT', "About to put a new group using this info:\n  grpName: #{grpName.inspect}\n  targetHost: #{targetHost.inspect}\n  rsrcPath: #{rsrcPath.inspect}\n  fieldMap: #{fieldMap.inspect}")
    apiReq = GbApi::JsonAsyncApiRequester.new(env, targetHost, @project)
    apiReq.bodyFinish {
      headers = apiReq.respHeaders
      status = apiReq.respStatus
      $stderr.debugPuts(__FILE__, __method__, 'PROTO ASYNC PUT', "Received back an async reply [will sendToClient]:\n  Status: #{status.inspect}\n  Headers:\n\n#{headers.inspect}\n\n")
      headers['Content-Type'] = "text/plain"
      apiReq.sendToClient(status, headers, JSON.generate(apiReq.respBody))
    }
    apiReq.put(rsrcPath, fieldMap, payload.to_json)
  end
end
