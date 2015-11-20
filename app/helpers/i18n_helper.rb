# -*- encoding : utf-8 -*-
module I18nHelper
  def locale_switcher form, *locales
    prefix = dom_id(form.object)
    buttons = ''.html_safe
    locales.flatten.each do |locale|
      buttons << content_tag(:li, content_tag(:a, locale.to_s.upcase, :href => '#'+ prefix + "_" + locale.to_s), :class => I18n.locale.to_s == locale.to_s ? "active" : "").html_safe
    end
    content_tag(:ul, buttons, :class => 'locale_switcher tabs small clearfix')
  end
  
  def locale_tabs form, *locales, &block
    fields = ''.html_safe
    locales.flatten.each do |locale|
      fields << content_tag(:ul, capture(I18nFormBuilder.new(locale, form), &block), id: dom_id(form.object) + "_" + locale.to_s)
    end
    content_tag(:li, content_tag(:div, fields, :class => 'tabs'))
  end

  def page_entries_info_custom(collection, options = {})
    model = options[:model]
    model = collection.first.class unless model or collection.empty?
    model ||= 'entry'
    model_key = if model.respond_to? :model_name
                  model.model_name.i18n_key  # ActiveModel::Naming
                else
                  model.to_s.underscore
                end

    if options.fetch(:html, true)
      b, eb = '<b>', '</b>'
      sp = '&nbsp;'
      html_key = '_html'
    else
      b = eb = html_key = ''
      sp = ' '
    end

    model_count = collection.total_pages > 1 ? 5 : collection.size
    defaults = ["models.#{model_key}"]
    defaults << Proc.new { |_, opts|
      if model.respond_to? :model_name
        model.model_name.human(:count => opts[:count])
      else
        name = model_key.to_s.tr('_', ' ')
        raise "can't pluralize model name: #{model.inspect}" unless name.respond_to? :pluralize
        opts[:count] == 1 ? name : name.pluralize
      end
    }
    model_name = will_paginate_translate defaults, :count => model_count

    if collection.total_pages < 2
      i18n_key = :"page_entries_info.single_page#{html_key}"
      keys = [:"#{model_key}.#{i18n_key}", i18n_key]

      will_paginate_translate keys, :count => collection.total_entries, :model => model_name do |_, opts|
        case opts[:count]
          when 0; "No #{opts[:model]} found"
          when 1; "Displaying #{b}1#{eb} #{opts[:model]}"
          else    "Displaying #{b}all#{sp}#{opts[:count]}#{eb} #{opts[:model]}"
        end
      end
    else
      i18n_key = :"page_entries_info.multi_page#{html_key}"
      keys = [:"#{model_key}.#{i18n_key}", i18n_key]
      params = {
        :model => model_name, :count => collection.total_entries,
        :count_with_delimiter => number_with_delimiter(collection.total_entries, :delimiter => ' '),
        :from_with_delimiter => number_with_delimiter(collection.offset + 1, :delimiter => ' '),
        :to_with_delimiter => number_with_delimiter(collection.offset + collection.length, :delimiter => ' '),
        :from => collection.offset + 1, :to => collection.offset + collection.length,
        :total_pages => collection.total_pages
      }
      will_paginate_translate keys, params do |_, opts|
        %{Displaying %s #{b}%d#{sp}-#{sp}%d#{eb} of #{b}%d#{eb} in total} %
          [ opts[:model], opts[:from], opts[:to], opts[:count] ]
      end
    end
  end
end
