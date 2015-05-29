# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::BaseController < BaseController
  include Unrollable, RestfullyManageable
  protect_from_forgery

  layout :dialog_or_not

  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_versioner

  include Userstamp

  protected

  # Overrides respond_with method in order to use specific parameters for reports
  # Adds :with and :key, :name parameters
  def respond_with_with_template(*resources, &block)
    resources << {} unless resources.last.is_a?(Hash)
    resources[-1][:with] = (params[:template].to_s.match(/^\d+$/) ? params[:template].to_i : params[:template].to_s) if params[:template]
    for param in [:key, :name]
      resources[-1][param] = params[param] if params[param]
    end
    respond_with_without_template(*resources, &block)
  end

  hide_action :respond_with, :respond_with_without_template
  alias_method_chain :respond_with, :template

  # Find a record with the current environment or given parameters and check availability of it
  def find_and_check(*args)
    options = args.extract_options!
    model = args.shift || options[:model] || self.controller_name.singularize
    id    = args.shift || options[:id] || params[:id]
    klass = nil
    begin
      klass = model.to_s.camelize.constantize
    rescue
      notify_error(:unexpected_resource_type, type: model.inspect)
      return false
    end
    unless klass < Ekylibre::Record::Base
      notify_error(:unexpected_resource_type, type: klass.model_name)
      return false
    end
    unless record = klass.find_by(id: id)
      notify_error(:unavailable_resource, type: klass.model_name.human, id: id)
      redirect_to_back
      return false
    end
    return record
  end

  def save_and_redirect(record, options={}, &block)
    record.attributes = options[:attributes] if options[:attributes]
    ActiveRecord::Base.transaction do
      if options[:saved] || record.send(:save)
        yield record if block_given?
        response.headers["X-Return-Code"] = "success"
        response.headers["X-Saved-Record-Id"] = record.id.to_s
        if params[:dialog]
          head :ok
        else
          # TODO: notify if success
          if options[:url] == :back
            redirect_to_back
          elsif params[:redirect]
            redirect_to params[:redirect]
          else
            url = options[:url]
            record.reload
            if url.is_a? Hash
              url.each do |k,v|
                url[k] = (v.is_a?(CodeString) ? record.send(v) : v)
              end
            end
            redirect_to(url)
          end
        end
        return true
      end
    end
    response.headers["X-Return-Code"] = "invalid"
    return false
  end

  # For title I18n : t3e :)
  def t3e(*args)
    @title ||= {}
    for arg in args
      arg = arg.attributes if arg.respond_to?(:attributes)
      unless arg.is_a? Hash
        raise ArgumentError, "Hash expected, got #{arg.class.name}:#{arg.inspect}"
      end
      arg.each do |k,v|
        @title[k.to_sym] = (v.respond_to?(:localize) ? v.localize : v.to_s)
      end
    end
  end

  private

  def dialog_or_not
    return (request.xhr? ? "popover" : params[:dialog] ? "dialog" : "backend")
  end


  # Set HTTP headers to block page caching
  def no_cache
    # Change headers to force zero cache
    response.headers["Last-Modified"] = Time.now.httpdate
    response.headers["Expires"] = '0'
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache"
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
  end

  def set_versioner
    Version.current_user = current_user
  end

  def set_theme
    # TODO: Dynamic theme choosing
    if current_user
      if %w(margarita tekyla tekyla-sunrise).include?(params[:theme])
        current_user.prefer!("theme", params[:theme])
      end
      @current_theme = current_user.preference("theme", "tekyla").value
    else
      @current_theme = "tekyla"
    end
  end


  # Controls access to every view in Ekylibre.
  def authorize_user!
    unless current_user.administrator?
      # Get accesses matching the current action
      list = Ekylibre::Access.rights_of("#{controller_path}##{action_name}")
      if list.empty?
        return true
        notify_error(:access_denied, reason: "OUT OF SCOPE", url: request.url.inspect)
        redirect_to root_url
        return false
      end

      # Search for one of found access in rights of current user
      list &= current_user.resource_actions
      unless list.any?
        notify_error(:access_denied, reason: "RESTRICTED", url: request.url.inspect)
        redirect_to root_url
        return false
      end
    end
    return true
  end

  def search_article(article = nil)
    # session[:help_history] = [] unless session[:help_history].is_a? [].class
    article ||= "#{self.controller_path}-#{self.action_name}"
    file = nil
    for locale in [I18n.locale, I18n.default_locale]
      for f, attrs in Ekylibre.helps
        next if attrs[:locale].to_s != locale.to_s
        file_name = [article, article.split("-")[0] + "-index"].detect{|name| attrs[:name] == name}
        file = f and break unless file_name.blank?
      end
      break unless file.nil?
    end
    # if file and session[:side] and article != session[:help_history].last
    #   session[:help_history] << file
    # end
    file ||= article.to_sym
    return file
  end

  def redirect_to_back(options={})
    if params[:redirect].present?
      redirect_to params[:redirect], options
    elsif request.referer and request.referer != request.fullpath
      redirect_to request.referer, options
    else
      redirect_to(root_url)
    end
  end

  def redirect_to_current(options={})
    ActiveSupport::Deprecation.warn("Use redirect_to_back instead of redirect_to_current")
    redirect_to_back(options.merge(direct: true))
  end

  class << self

    # Autocomplete helper
    def autocomplete_for(column, options = {})
      model = (options.delete(:model) || controller_name).to_s.classify.constantize
      item =  model.name.underscore.to_s
      items = item.pluralize
      items = "many_#{items}" if items == item
      code =  "def #{__method__}_#{column}\n"
      code << "  if params[:term]\n"
      code << "    pattern = '%'+params[:term].to_s.mb_chars.downcase.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'\n"
      code << "    @#{items} = #{model.name}.select('DISTINCT #{column}').where('LOWER(#{column}) LIKE ?', pattern).order('#{column} ASC').limit(80)\n"
      code << "    respond_to do |format|\n"
      code << "      format.html { render :inline => \"<%=content_tag(:ul, @#{items}.map { |#{item}| content_tag(:li, #{item}.#{column})) }.join.html_safe)%>\" }\n"
      code << "      format.json { render :json => @#{items}.collect{|#{item}| #{item}.#{column}}.to_json }\n"
      code << "    end\n"
      code << "  else\n"
      code << "    render :text => '', :layout => true\n"
      code << "  end\n"
      code << "end\n"
      class_eval(code, "#{__FILE__}:#{__LINE__}")
    end

    # search is a hash like {table: [columns...]}
    def search_conditions(search = {}, options={})
      conditions = options[:conditions] || 'c'
      options[:except]  ||= []
      options[:filters] ||= {}
      variable ||= options[:variable] || "params[:q]"
      tables = search.keys.select{|t| !options[:except].include? t}
      code = "\n#{conditions} = ['1=1']\n"
      columns = search.collect do |table, filtered_columns|
        filtered_columns.collect do |column|
          ActiveRecord::Base.connection.quote_table_name(table.is_a?(Symbol) ? table.to_s.classify.constantize.table_name : table) +
            "." +
            ActiveRecord::Base.connection.quote_column_name(column)
        end
      end.flatten
      code << "for kw in #{variable}.to_s.lower.split(/\\s+/)\n"
      code << "  kw = '%'+kw+'%'\n"
      filters = columns.collect do |x|
        'LOWER(CAST('+x.to_s+' AS VARCHAR)) LIKE ?'
      end
      values = '['+(['kw']*columns.size).join(', ')+']'
      for k, v in options[:filters]
        filters << k
        v = '['+v.join(', ')+']' if v.is_a? Array
        values += "+"+v
      end
      code << "  #{conditions}[0] += ' AND (#{filters.join(' OR ')})'\n"
      code << "  #{conditions} += #{values}\n"
      code << "end\n"
      code << "#{conditions}"
      return code.c
    end


    # accountancy -> accounts_range_crit
    def accounts_range_crit(variable, conditions='c')
      variable = "params[:#{variable}]" unless variable.is_a? String
      code = ""
      # code << "ac, #{variable}[:accounts] = \n"
      code << "#{conditions}[0] += ' AND '+Account.range_condition(#{variable}[:accounts])\n"
      return code.c
    end

    # accountancy -> crit_params
    def crit_params(hash)
      nh = {}
      keys = JournalEntry.state_machine.states.collect{|s| s.name}
      keys += [:period, :started_at, :stopped_at, :accounts, :centralize]
      for k, v in hash
        nh[k] = hash[k] if k.to_s.match(/^(journal|level)_\d+$/) or keys.include? k.to_sym
      end
      return nh
    end

    # accountancy -> journal_entries_states_crit
    def journal_entries_states_crit(variable, conditions='c')
      variable = "params[:#{variable}]" unless variable.is_a? String
      code = ""
      code << "#{conditions}[0] += ' AND '+JournalEntry.state_condition(#{variable}[:states])\n"
      return code.c
    end

    # accountancy -> journal_period_crit
    def journal_period_crit(variable, conditions='c')
      variable = "params[:#{variable}]" unless variable.is_a? String
      code = ""
      code << "#{conditions}[0] += ' AND '+JournalEntry.period_condition(#{variable}[:period], #{variable}[:started_at], #{variable}[:stopped_at])\n"
      return code.c
    end

    # accountancy -> journals_crit
    def journals_crit(variable, conditions='c')
      variable = "params[:#{variable}]" unless variable.is_a? String
      code = ""
      code << "#{conditions}[0] += ' AND '+JournalEntry.journal_condition(#{variable}[:journals])\n"
      return code.c
    end
  end

end
