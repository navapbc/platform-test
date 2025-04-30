class BreadcrumbsPreview < Lookbook::Preview
  layout "component_preview"

  def default
    render template: "application/_breadcrumbs", locals: { crumbs: [
      { name: "Passport applications", url: "https://google.com" },
      ], current_name: "New passport application" } 
  end
end
