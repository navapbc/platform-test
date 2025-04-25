class DummyComponentPreview < ViewComponent::Preview
  def default
    render(DummyComponent.new(message: "Lookbook preview is a go."))
  end

  def custom_message
    render(DummyComponent.new(message: "Today's such a wonderful day, let's just make a happy little painting. Maybe I'll have a bit mountain today. You can do anything that you believe you can do. Get it to where you want it, and leave it alone. That's the fun part of this whole technique."))
  end
end
