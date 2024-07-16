local function RGB(R,G,B,A)
	return {R/255, G/255, B/255, (A==nil and 255 or A)/255}
end

return {
	Title = RGB(73, 56, 0, 127);
	Background = RGB(170, 144, 57);
	Text = RGB(255, 240, 218);
	Selected = RGB(0, 255, 0); --TODO better color
	Card = {
		Border = RGB(154, 166, 178);
		Focused = {
			Body = RGB(43, 76, 111);
			Shadow = RGB(2, 24, 48);
		};
		Unfocused = {
			Body = RGB(55, 50, 118);
			Shadow = RGB(7, 3, 52);
		};
	};
	Steam = {
		Installed = RGB(55,200,46);
	};
}
