module Admin::Resources::DataTypes::BelongsToHelper

  def typus_belongs_to_field(attribute, form)
    association = @resource.reflect_on_association(attribute.to_sym)

    related = if defined?(set_belongs_to_context)
      set_belongs_to_context.send(attribute.pluralize.to_sym)
    else
      association.class_name.constantize
    end

    related_fk = association.foreign_key
    html_options = { :disabled => attribute_disabled?(attribute) }
    label_text = @resource.human_attribute_name(attribute)
    options = { :attribute => "#{@resource.name.downcase}_#{related_fk}" }

    label_text = @resource.human_attribute_name(attribute)
    if (text = build_label_text_for_belongs_to(related, html_options, options))
      label_text += "<small>#{text}</small>"
    end
    if (text = belongs_to_field(attribute, form.object, true))
      label_text += "<small>#{text}</small>"
    end

    values = if related.respond_to?(:roots)
      expand_tree_into_select_field(related.roots, related_fk)
    else
      related.order(related.typus_order_by).map { |p| [p.to_label, p.id] }
    end

    attribute_id = "#{@resource.name.underscore}_#{attribute}_id".gsub("/", "_")

    render "admin/templates/belongs_to",
           :attribute => attribute,
           :attribute_id => attribute_id,
           :form => form,
           :related_fk => related_fk,
           :related => related,
           :label_text => label_text.html_safe,
           :values => values,
           :html_options => html_options,
           :options => { :include_blank => true }
  end

  def belongs_to_field(attribute, item, link_required = false)
    if att_value = item.send(attribute)
      action = item.send(attribute).class.typus_options_for(:default_action_on_item)
      label = att_value.to_label
      if !params[:_popup] && admin_user.can?(action, att_value.class.name)
        message = link_to(label, :controller => "/admin/#{att_value.class.to_resource}", :action => action, :id => att_value.id)
      elsif !link_required
        message = label
      end
    end
    message
  end

  def table_belongs_to_field(attribute, item)
    belongs_to_field(attribute, item) || mdash
  end

  def display_belongs_to(item, attribute)
    belongs_to_field(attribute, item)
  end

  def belongs_to_filter(filter)
    att_assoc = @resource.reflect_on_association(filter.to_sym)
    class_name = att_assoc.options[:class_name] || filter.capitalize.camelize
    resource = class_name.constantize

    items = [[Typus::I18n.t("View all %{attribute}", :attribute => @resource.human_attribute_name(filter).downcase.pluralize), ""]]
    items += resource.order(resource.typus_order_by).map { |v| [v.to_label, v.id] }
  end

  def build_label_text_for_belongs_to(klass, html_options, options)
    if html_options[:disabled] == true
      Typus::I18n.t("Read only")
    elsif admin_user.can?('create', klass) && !headless_mode?
      build_add_new_for_belongs_to(klass, options)
    end
  end

  def build_add_new_for_belongs_to(klass, options)
    default_options = { :controller => "/admin/#{klass.to_resource}",
                        :action => 'new',
                        :attribute => options[:attribute],
                        :_popup => true }
    link_to Typus::I18n.t("Add New"), default_options, { :class => 'iframe' }
  end

end
