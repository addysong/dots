from kitty.fast_data_types import get_boss, get_options, wcswidth
from kitty.tab_bar import as_rgb, draw_tab_with_powerline

DEFAULT_TITLE = "    "

MODE_DISPLAY = {
    "p": ("󰄛 ", 4),
    "resize": (" ", 5),
}


def draw_title(data):
    tab = get_boss().tab_for_id(data["tab_id"])

    if tab is None or not tab.name:
        return DEFAULT_TITLE

    return tab.name


def draw_tab(
    draw_data,
    screen,
    tab,
    before,
    max_tab_length,
    index,
    is_last,
    extra_data,
):
    end = draw_tab_with_powerline(
        draw_data,
        screen,
        tab,
        before,
        max_tab_length,
        index,
        is_last,
        extra_data,
    )

    if is_last and not extra_data.for_layout:
        marker = MODE_DISPLAY.get(get_boss().mappings.current_keyboard_mode_name)
        if marker is None:
            return end

        label, color_index = marker
        marker_start = screen.columns - len(label)

        if marker_start > end:
            screen.cursor.x = marker_start
            screen.cursor.bg = 0
            screen.cursor.fg = as_rgb(get_options().color_table[color_index])
            screen.draw(label)

    return end
