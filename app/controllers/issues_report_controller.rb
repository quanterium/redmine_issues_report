class IssuesReportController < ApplicationController
  
  helper :sort
  include SortHelper
  helper :queries
  include QueriesHelper
  helper :issues
  include IssuesHelper
  helper :journals
  helper :custom_fields
  include CustomFieldsHelper
  
  def index

  end    
  
  def generate   
    @project=Project.find(params[:project_id])
    retrieve_query    
    logger.info "Anzahl aus Query: #{@query.issue_count} Projekt: #{@project}"
    sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
    if @query.valid?
      @limit = per_page_option
      @query.sort_criteria = sort_criteria.to_a
      @issue_count = @query.issue_count
      @issue_pages = Paginator.new @issue_count, @limit, params['page']
      @offset ||= @issue_pages.offset
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group           
    end

    respond_to do |format|
      format.html { render :template => 'issues_report/report_list' }
      format.api
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  {
        send_file_headers! :type => 'application/pdf', :filename => "#{@project.identifier}-detailed.pdf"
      }
    end
  end

end