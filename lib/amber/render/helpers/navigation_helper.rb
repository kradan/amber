module Amber
  module Render
    module NavigationHelper

      def has_navigation?
        if current_page_path.empty? || @site.menu.nil?
          false
        else
          submenu = @site.menu.submenu(current_page_path.first)
          if submenu
            second_level_children_count = submenu.size
            if second_level_children_count.nil?
              false
            else
              second_level_children_count >= 1
            end
          else
            false
          end
        end
      end

      #
      # yields each item
      #
      def top_navigation_items(options={})
        if !@site.menu
          yield({})
        else
          first = 'first'
          if options[:include_home]
            active = current_page_path.empty? ? 'active' : ''
            yield({:class => [first, active].compact.join(' '), :href => menu_item_path(@site.menu), :label => menu_item_title(@site.menu)})
            first = nil
          end
          @site.menu.each do |item|
            active = current_page_path.first == item.name ? 'active' : ''
            yield({:class => [first, active].compact.join(' '), :href => menu_item_path(item), :label => menu_item_title(item)})
            first = nil
          end
        end
      end

      #
      # yields each item
      #
      def navigation_items(menu=nil, level=1, &block)
        if menu.nil?
          menu = site.menu.submenu(current_page_path.first)
        end
        if menu
          menu.each do |item|
            title = menu_item_title(item)
            if title
              yield({
                :href => menu_item_path(item),
                :level => level,
                :active => path_active_class(current_page_path, item),
                :label => title
              })
            end
            if path_open?(current_page_path, item)
              navigation_items(item.submenu, level+1, &block)
            end
          end
        end
      end

      def current_page_path
        @current_page_path ||= begin
          if @page
            @page.path
          #elsif params[:page].is_a? String
          #  params[:page].split('/')
          else
            []
          end
        end
      end

      def menu_item_path(item)
        "/#{I18n.locale}/#{item.path.join('/')}"
      end

      def menu_item_title(item)
        page = @site.find_page_by_path(item.path_str) || @site.find_page_by_name(item.name)
        if page
          page.nav_title(I18n.locale)
        else
          nil
        end
      end

      private

      #
      # returns string 'active', 'semi-active', or ''
      #
      def path_active_class(page_path, menu_item)
        active = ''
        if menu_item.path == page_path
          active = 'active'
        elsif menu_item.path_prefix_of?(page_path)
          if menu_item.leaf_for_path?(page_path)
            active = 'active'
          else
            active = 'semi-active'
          end
        end
        active
      end

      #
      # returns true if menu_item represents an parent of page
      #
      def path_open?(page_path, menu_item)
        menu_item.path == page_path || menu_item.path_prefix_of?(page_path)
      end

      #
      # inserts an directory index built from the page's children
      #
      def child_summaries(options={})
        page = options.delete(:page) || @page
        return unless page
        locale = @locals[:locale]
        menu = submenu_for_page(page)
        return unless menu
        haml do
          menu.children.each do |submenu|
            child_page = page.child(submenu.name)
            next unless child_page # might be an entry in menu.txt with no actual page
            haml :h3 do
              haml :a, child_page.nav_title(locale), :href => page_path(child_page)
            end
            if summary = child_page.prop(locale, 'summary')
              haml :p, summary
            end
            if options[:include_toc]
              toc_html = render_toc(child_page)
              haml :div, toc_html
            end
          end
        end
      end

      def submenu_for_page(page)
        menu = @site.menu
        page.path.each do |segment|
          menu = menu.submenu(segment)
        end
        return menu
      rescue
        return nil
      end

    end
  end
end


=begin

  def act_as(page)
    page = site.find_page(page)
    @current_page_path = page.path
    page_body(page)
  end

  def child_summaries(page=@page)
    return unless page
    menu = submenu_for_page(page)
    return unless menu
    haml do
      menu.children.each do |submenu|
        child_page = page.child(submenu.name)
        haml :h3 do
          haml :a, child_page.nav_title, :href => page_path(child_page)
        end
        haml :p, child_page.props.summary
      end
    end
  end

=end