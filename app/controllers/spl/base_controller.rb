module Spl
  class BaseController < ApplicationController
    before_action :authenticate_spl_user!
    layout 'spl_application'
  end
end
