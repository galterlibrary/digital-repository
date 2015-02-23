# -*- coding: utf-8 -*-
class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Galtersufia::FilesControllerBehavior
end
