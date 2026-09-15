function Entity:icon()
  local icon = self._file:icon()
  if not icon then
    return ""
  end

  local style = icon.style
  if self._file.is_hovered then
    style = style:reverse(true)
  end

  return ui.Line(icon.text .. " "):style(style)
end

function Entity:padding()
  if not self._file.is_hovered or self._file.in_preview then
    return " "
  end

  return ui.Span(th.indicator.padding.open):style(self:style_rev() or ui.Style())
end
