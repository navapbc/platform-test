class BreadcrumbsPreview < Lookbook::Preview
  def default
    result = render template: "application/_breadcrumbs", locals: { crumbs: [
      { name: "Passport applications", url: "https://google.com" },
      ], current_name: "New passport application" } 
  end
end
