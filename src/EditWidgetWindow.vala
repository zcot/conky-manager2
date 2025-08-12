/*
 * EditWidgetWindow.vala
 * 
 * Copyright 2015 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class EditWidgetWindow : Dialog {
	private Notebook tab_widget_properties;
	private Label lbl_background_color;
	private Label lbl_alignment;
	private Label lbl_gap_x;
	private Label lbl_gap_y;
	private Label lbl_transparency;
	private Label lbl_min_width;
	private Label lbl_min_height;
	private Label lbl_widget_time_not_found;
	private Label lbl_widget_network_not_found;
	private ComboBox cmb_alignment;
	private ComboBox cmb_transparency_type;
	private ComboBox cmb_time_format;
	private SpinButton spin_gap_x;
	private SpinButton spin_gap_y;
	private SpinButton spin_opacity;
	private SpinButton spin_min_width;
	private SpinButton spin_min_height;
	private SpinButton spin_height_padding;
	private ColorButton cbtn_bg_color;
	private Entry txt_network_device;
	private Button btn_wifi;
	private Button btn_lan;
	private Button btn_apply_changes;
	private Button btn_discard_changes;
	private Button btn_cancel_changes;
	private ConkyRC conkyrc;
	
	public EditWidgetWindow(ConkyRC conkyrc_edit) {
		title = _("Edit Widget");
        window_position = WindowPosition.CENTER_ON_PARENT;
		set_destroy_with_parent (true);
		set_modal (true);
        skip_taskbar_hint = true;
        set_default_size (400, 20);	
		icon = get_app_icon(16);
		
		conkyrc = conkyrc_edit;

	    Box vbox_main = get_content_area();
	    
        CellRendererText textCell;
        
        int page_margin = 12;
        
        //tab_widget_properties ---------------------------------------
        tab_widget_properties = new Notebook ();
		tab_widget_properties.margin = 6;
		tab_widget_properties.expand = true;
		tab_widget_properties.set_size_request(-1,400);
		vbox_main.add(tab_widget_properties);
		
		//lblWidgetLocation
		Label lblWidgetLocation = new Label (_("Location"));

		//grid_widget_location -----------------------------------------------
		
        Grid grid_widget_location = new Grid ();
        grid_widget_location.set_column_spacing (12);
        grid_widget_location.set_row_spacing (6);
        grid_widget_location.column_homogeneous = false;
        grid_widget_location.visible = false;
        grid_widget_location.margin = page_margin;
        tab_widget_properties.append_page (grid_widget_location, lblWidgetLocation);
        
		int row = -1;
		string tt;
		
		//lbl_alignment
		lbl_alignment = new Gtk.Label(_("Alignment"));
		lbl_alignment.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_alignment,0,++row,1,1);
		
		//cmb_alignment
		cmb_alignment = new ComboBox();
		textCell = new CellRendererText();
        cmb_alignment.pack_start( textCell, false );
        cmb_alignment.set_attributes( textCell, "text", 0 );
        grid_widget_location.attach(cmb_alignment,1,row,1,1);
		
		//populate
		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Top Left"),1,"top_left");
		model.append (out iter);
		model.set (iter,0,_("Top Right"),1,"top_right");
		model.append (out iter);
		model.set (iter,0,_("Top Middle"),1,"top_middle");
		model.append (out iter);
		model.set (iter,0,_("Bottom Left"),1,"bottom_left");
		model.append (out iter);
		model.set (iter,0,_("Bottom Right"),1,"bottom_right");
		model.append (out iter);
		model.set (iter,0,_("Bottom Middle"),1,"bottom_middle");
		model.append (out iter);
		model.set (iter,0,_("Middle Left"),1,"middle_left");
		model.append (out iter);
		model.set (iter,0,_("Middle Right"),1,"middle_right");
		model.append (out iter);
		model.set (iter,0,_("Middle Middle"),1,"middle_middle");
		cmb_alignment.set_model(model);
		
		//lbl_gap_x
		lbl_gap_x = new Gtk.Label(_("Horizontal Gap"));
		lbl_gap_x.set_tooltip_text(_("[GAP_X] Horizontal distance from window border (in pixels)"));
		lbl_gap_x.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_gap_x,0,++row,1,1);
		
		//spin_gap_x
		spin_gap_x = new SpinButton.with_range(-10000,10000,10);
		spin_gap_x.xalign = (float) 0.5;
		spin_gap_x.value = 0.0;
		grid_widget_location.attach(spin_gap_x,1,row,1,1);
		
		//lbl_gap_y
		lbl_gap_y = new Gtk.Label(_("Vertical Gap"));
		lbl_gap_y.set_tooltip_text(_("[GAP_Y] Vertical distance from window border (in pixels)"));
		lbl_gap_y.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_gap_y,0,++row,1,1);
		
		//spin_gap_y
		spin_gap_y = new SpinButton.with_range(-10000,10000,10);
		spin_gap_y.xalign = (float) 0.5;
		spin_gap_y.value = 0.0;
		spin_gap_y.set_size_request(120,-1);
		grid_widget_location.attach(spin_gap_y,1,row,1,1);

		//lblWidgetSize
		Label lblWidgetSize = new Label (_("Size"));

		//grid_widget_size  -----------------------------------------------------------
		
        Grid grid_widget_size = new Grid ();
        grid_widget_size.set_column_spacing (12);
        grid_widget_size.set_row_spacing (6);
        grid_widget_size.column_homogeneous = false;
        grid_widget_size.visible = false;
        grid_widget_size.margin = page_margin;
        grid_widget_size.border_width = 1;
        tab_widget_properties.append_page (grid_widget_size, lblWidgetSize);
        
        row = -1;
        
        tt = _("Width should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lbl_min_width
		lbl_min_width = new Gtk.Label(_("Minimum Width"));
		lbl_min_width.xalign = (float) 0.0;
		lbl_min_width.set_tooltip_text(tt);
		grid_widget_size.attach(lbl_min_width,0,++row,1,1);
		
		//spin_min_width
		spin_min_width = new SpinButton.with_range(0,9999,10);
		spin_min_width.xalign = (float) 0.5;
		spin_min_width.value = 100.0;
		spin_min_width.set_size_request(120,-1);
		spin_min_width.set_tooltip_text(tt);
		grid_widget_size.attach(spin_min_width,1,row,1,1);
		
		tt = _("Height should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lbl_min_height
		lbl_min_height = new Gtk.Label(_("Minimum Height"));
		lbl_min_height.xalign = (float) 0.0;
		lbl_min_height.set_tooltip_text(tt);
		grid_widget_size.attach(lbl_min_height,0,++row,1,1);
		
		//spin_min_height
		spin_min_height = new SpinButton.with_range(0,9999,10);
		spin_min_height.xalign = (float) 0.5;
		spin_min_height.value = 100.0;
		spin_min_height.set_tooltip_text(tt);
		grid_widget_size.attach(spin_min_height,1,row,1,1);
		
		tt = _("Increases the window height by adding empty lines at the end of the Conky config file");
		
		//lblTrailingLines
		Label lblTrailingLines = new Gtk.Label(_("Height Padding"));
		lblTrailingLines.xalign = (float) 0.0;
		lblTrailingLines.set_tooltip_text(tt);
		grid_widget_size.attach(lblTrailingLines,0,++row,1,1);
		
		//spin_height_padding
		spin_height_padding = new SpinButton.with_range(0,100,1);
		spin_height_padding.xalign = (float) 0.5;
		spin_height_padding.value = 0.0;
		spin_height_padding.set_tooltip_text(tt);
		grid_widget_size.attach(spin_height_padding,1,row,1,1);
		
		//lblSizeExpander
		Label lblSizeExpander = new Gtk.Label("");
		lblSizeExpander.vexpand = true;
		grid_widget_size.attach(lblSizeExpander,0,++row,3,1);
		
		tt = "Ø " + _("The minimum width & height must be more than the size of the window contents, otherwise the setting will not have any effect.");
		
		//lblSize1
		Label lblSize1 = new Gtk.Label(tt);
		lblSize1.margin_bottom = 6;
		lblSize1.xalign = (float) 0.0;
		lblSize1.set_size_request(100,-1);
		lblSize1.set_line_wrap(true);
		grid_widget_size.attach(lblSize1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Opaque\" (from the transparency tab) will make it easier to see the changes");
		
		//lbl_size2
		Label lbl_size2 = new Gtk.Label(tt);
		lbl_size2.margin_bottom = 6;
		lbl_size2.xalign = (float) 0.0;
		lbl_size2.set_size_request(100,-1);
		lbl_size2.set_line_wrap(true);
		grid_widget_size.attach(lbl_size2,0,++row,3,1);
		
		//lblWidgetTransparency
		Label lblWidgetTransparency = new Label (_("Transparency"));

		//grid_widget_transparency  -----------------------------------------------------------
		
        Grid grid_widget_transparency = new Grid ();
        grid_widget_transparency.set_column_spacing (12);
        grid_widget_transparency.set_row_spacing (6);
        grid_widget_transparency.column_homogeneous = false;
        grid_widget_transparency.visible = false;
        grid_widget_transparency.margin = page_margin;
        tab_widget_properties.append_page (grid_widget_transparency, lblWidgetTransparency);
        
        row = -1;
        
        tt = "";
        
        //lblBackgroundType
		Label lblBackgroundType = new Gtk.Label(_("Transparency Type"));
		lblBackgroundType.xalign = (float) 0.0;
		lblBackgroundType.set_tooltip_text(tt);
		lblBackgroundType.set_use_markup(true);
		grid_widget_transparency.attach(lblBackgroundType,0,row,1,1);
		
        //cmb_transparency_type
		cmb_transparency_type = new ComboBox();
		textCell = new CellRendererText();
        cmb_transparency_type.pack_start( textCell, false );
        cmb_transparency_type.set_attributes( textCell, "text", 0 );
        cmb_transparency_type.changed.connect(cmb_transparency_type_changed);
		cmb_transparency_type.set_tooltip_text(tt);
        grid_widget_transparency.attach(cmb_transparency_type,1,row,2,1);
		
		//populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Opaque"),1,"opaque");
		model.append (out iter);
		model.set (iter,0,_("Transparent"),1,"trans");
		model.append (out iter);
		model.set (iter,0,_("Pseudo-Transparent"),1,"pseudo");
		model.append (out iter);
		model.set (iter,0,_("Semi-Transparent"),1,"semi");
		cmb_transparency_type.set_model(model);

		tt = _("Window Opacity\n\n0 = Fully Transparent, 100 = Fully Opaque");
		
		//lbl_transparency
		lbl_transparency = new Gtk.Label(_("Opacity (%)"));
		lbl_transparency.set_tooltip_text(tt);
		lbl_transparency.xalign = (float) 0.0;
		grid_widget_transparency.attach(lbl_transparency,0,++row,1,1);
		
		//spin_opacity
		spin_opacity = new SpinButton.with_range(0,100,10);
		spin_opacity.set_tooltip_text(tt);
		spin_opacity.xalign = (float) 0.5;
		spin_opacity.value = 100.0;
		//spin_opacity.set_size_request(120,-1);
		grid_widget_transparency.attach(spin_opacity,1,row,1,1);
		
		//lbl_background_color
		lbl_background_color = new Gtk.Label(_("Background Color"));
		lbl_background_color.xalign = (float) 0.0;
		grid_widget_transparency.attach(lbl_background_color,0,++row,1,1);
		
		//cbtn_bg_color
		cbtn_bg_color = new ColorButton();
		grid_widget_transparency.attach(cbtn_bg_color,1,row,1,1);
		
		//lbl_transparencyExpander
		Label lbl_transparencyExpander = new Gtk.Label("");
		lbl_transparencyExpander.vexpand = true;
		grid_widget_transparency.attach(lbl_transparencyExpander,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Transparent\" will make the whole window transparent (including any images). Use \"Pseudo-Transparent\" if you want the images to be opaque.");
		
		//lblTrans1
		Label lblTrans1 = new Gtk.Label(tt);
		lblTrans1.margin_bottom = 6;
		lblTrans1.xalign = (float) 0.0;
		lblTrans1.set_size_request(100,-1);
		lblTrans1.set_line_wrap(true);
		grid_widget_transparency.attach(lblTrans1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Pseudo-Transparent\" will make the window transparent but the window will have a shadow. The shadow can be disabled by configuring your window manager.");
		
		//lblTrans2
		Label lblTrans2 = new Gtk.Label(tt);
		lblTrans2.margin_bottom = 6;
		lblTrans2.xalign = (float) 0.0;
		lblTrans2.set_size_request(100,-1);
		lblTrans2.set_line_wrap(true);
		grid_widget_transparency.attach(lblTrans2,0,++row,3,1);

		//lbl_widget_time
		Label lbl_widget_time = new Label (_("Time"));

		//grid_widget_time  -----------------------------------------------------------
		
        Grid grid_widget_time = new Grid ();
        grid_widget_time.set_column_spacing (12);
        grid_widget_time.set_row_spacing (6);
        grid_widget_time.column_homogeneous = false;
        grid_widget_time.visible = false;
        grid_widget_time.margin = page_margin;
        grid_widget_time.border_width = 1;
        tab_widget_properties.append_page (grid_widget_time, lbl_widget_time);
		
		row = -1;
		
        //lblTimeFormat
		Label lblTimeFormat = new Gtk.Label(_("Time Format"));
		lblTimeFormat.xalign = (float) 0.0;
		lblTimeFormat.set_use_markup(true);
		grid_widget_time.attach(lblTimeFormat,0,++row,1,1);
		
        //cmb_time_format
		cmb_time_format = new ComboBox();
		textCell = new CellRendererText();
        cmb_time_format.pack_start( textCell, false );
        cmb_time_format.set_attributes( textCell, "text", 0 );
        grid_widget_time.attach(cmb_time_format,1,row,1,1);
		
		//lbl_widget_time_not_found
		lbl_widget_time_not_found = new Gtk.Label("");
		lbl_widget_time_not_found.set_use_markup(true);
		lbl_widget_time_not_found.xalign = (float) 0.0;
		lbl_widget_time_not_found.margin = 6;
		grid_widget_time.attach(lbl_widget_time_not_found,0,++row,2,1);
		
		//populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("12 Hour"),1,"12");
		model.append (out iter);
		model.set (iter,0,_("24 Hour"),1,"24");
		cmb_time_format.set_model(model);
		
		//lblWidgetNetwork
		Label lblWidgetNetwork = new Label (_("Network"));

		//grid_widget_network  -----------------------------------------------------------
		
        Grid grid_widget_network = new Grid ();
        grid_widget_network.set_column_spacing (12);
        grid_widget_network.set_row_spacing (6);
        grid_widget_network.column_homogeneous = false;
        grid_widget_network.visible = false;
        grid_widget_network.margin = page_margin;
        grid_widget_network.border_width = 1;
        tab_widget_properties.append_page (grid_widget_network, lblWidgetNetwork);
		
		row = -1;

        //lblNetworkDevice
		Label lblNetworkDevice = new Gtk.Label(_("Interface"));
		lblNetworkDevice.xalign = (float) 0.0;
		lblNetworkDevice.set_use_markup(true);
		grid_widget_network.attach(lblNetworkDevice,0,++row,1,1);
		
		//txt_network_device
        txt_network_device =  new Gtk.Entry();
        grid_widget_network.attach(txt_network_device,1,row,1,1);
        
        //btn_wifi
        btn_wifi = new Button.with_label(_("WiFi"));
        btn_wifi.clicked.connect (() => {
			txt_network_device.text = "wlan0";
			});
		btn_wifi.set_size_request(50,-1);
        btn_wifi.set_tooltip_text (_("WiFi Network") + " (wlan0)");
		grid_widget_network.attach(btn_wifi,2,row,1,1);
		
        //btn_lan
        btn_lan = new Button.with_label(_("LAN"));
        btn_lan.clicked.connect (() => {
			txt_network_device.text = "eth0";
			});
		btn_lan.set_size_request(50,-1);
        btn_lan.set_tooltip_text (_("Wired LAN Network") + " (eth0)");
		grid_widget_network.attach(btn_lan,3,row,1,1);

		//lbl_widget_network_not_found
		lbl_widget_network_not_found = new Gtk.Label("");
		lbl_widget_network_not_found.set_use_markup(true);
		lbl_widget_network_not_found.xalign = (float) 0.0;
		lbl_widget_network_not_found.margin = 6;
		grid_widget_network.attach(lbl_widget_network_not_found,0,++row,4,1);
		
		//hbox_commands --------------------------------------------------
		
		Box hbox_action = (Box) get_action_area();
		
		//btn_apply_changes
		btn_apply_changes = new Button.with_label("  " + _("Apply"));
		btn_apply_changes.set_image (new Image.from_stock ("gtk-apply", IconSize.MENU));
        btn_apply_changes.clicked.connect (btn_apply_changes_clicked);
        btn_apply_changes.set_tooltip_text (_("Apply Changes"));
        //btn_apply_changes.set_size_request(-1,30);
		hbox_action.add(btn_apply_changes);
		
		//btn_discard_changes
		btn_discard_changes = new Button.with_label("  " + _("Reset"));
		btn_discard_changes.set_image (new Image.from_stock ("gtk-clear", IconSize.MENU));
        btn_discard_changes.clicked.connect (btn_discard_changes_clicked);
        btn_discard_changes.set_tooltip_text (_("Reset Changes"));
        //btn_discard_changes.set_size_request(-1,30);
		hbox_action.add(btn_discard_changes);

		//btn_cancel_changes
		btn_cancel_changes = new Button.with_label("  " + _("Close"));
		btn_cancel_changes.set_image (new Image.from_stock ("gtk-cancel", IconSize.MENU));
        btn_cancel_changes.clicked.connect (btn_cancel_changes_clicked);
        btn_cancel_changes.set_tooltip_text (_("Discard Changes"));
        //btn_cancel_changes.set_size_request(-1,30);
		hbox_action.add(btn_cancel_changes);
		
		reload_widget_properties();
	}

	private void reload_widget_properties(){
		ConkyRC conf = conkyrc;
		
		debug("-----------------------------------------------------");
		debug(_("Loading") + ": %s".printf(conf.name));

		conf.read_file();
		
		//check for 1.10 config version
		//default: one_ten_config = false;
		string std_out = "";
		string std_err = "";
		string cmd = "grep -r \"conky\\.text[[:blank:]]*=\" \"%s\"".printf(conf.path);
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);

		if (exit_code == 0){
			conf.one_ten_config = true;
		}

		//location
		gtk_combobox_set_value(cmb_alignment, 1, conf.alignment);
		spin_gap_x.value = double.parse(conf.gap_x);
		spin_gap_y.value = double.parse(conf.gap_y);
		
		//transparency
		gtk_combobox_set_value(cmb_transparency_type,1,conf.transparency);
		
		if (conf.own_window_argb_value == ""){
			spin_opacity.value = 0;
		}
		else{
			spin_opacity.value = (int.parse(conf.own_window_argb_value) / 255.0) * 100;
		}
		cbtn_bg_color.rgba = hex_to_rgba(conf.own_window_colour);
		
		//window size 
		if (conf.one_ten_config){
			spin_min_width.value = int.parse(conf.minimum_width);
			spin_min_height.value = int.parse(conf.minimum_height);
		}
		else{
			string size = conf.minimum_size;
			spin_min_width.value = int.parse(size.split(" ")[0]);
			spin_min_height.value = int.parse(size.split(" ")[1]);
		}
		spin_height_padding.value = conf.height_padding;
		
		//time
		string time_format = conf.time_format;
		
		if (time_format == "") {
			cmb_time_format.sensitive = false;
			lbl_widget_time_not_found.label = "<i>Ø " + _("Time format cannot be changed for selected widget") + "</i>";
		}
		else{
			cmb_time_format.sensitive = true;
			lbl_widget_time_not_found.label = "";
		}
		
		if (time_format == "") { time_format = "12"; }
		gtk_combobox_set_value(cmb_time_format,1,time_format);
		
		//network
		string net = conf.network_device;
		if (net == ""){
			txt_network_device.sensitive = false;
			btn_wifi.sensitive = false;
			btn_lan.sensitive = false;
			lbl_widget_network_not_found.label = "<i>Ø " + _("Network interface cannot be changed for selected widget") + "</i>";
			txt_network_device.text = "";
		}
		else{
			txt_network_device.sensitive = true;
			btn_wifi.sensitive = true;
			btn_lan.sensitive = true;
			lbl_widget_network_not_found.label = "";
			txt_network_device.text = net.strip();
		}

		debug("-----------------------------------------------------");
	}
	
	private void btn_apply_changes_clicked () {
		gtk_set_busy(true, this);

		ConkyRC conf = conkyrc;
		
		conf.stop();
		conf.read_file();
		
		//check for 1.10 config version
		//default: one_ten_config = false;
		string std_out = "";
		string std_err = "";
		string cmd = "grep -r \"conky\\.text[[:blank:]]*=\" \"%s\"".printf(conf.path);
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);

		if (exit_code == 0){
			conf.one_ten_config = true;
		}

		debug("-----------------------------------------------------");
		debug(_("Updating theme") + ": %s".printf(conf.name));

		//location
		conf.alignment = gtk_combobox_get_value(cmb_alignment,1,"top_left");
		conf.gap_x = spin_gap_x.value.to_string();
		conf.gap_y = spin_gap_y.value.to_string();
		
		//transparency
		conf.transparency = gtk_combobox_get_value(cmb_transparency_type,1,"semi");
		conf.own_window_argb_value = "%.0f".printf((spin_opacity.value / 100.0) * 255.0);
		conf.own_window_colour = rgba_to_hex(cbtn_bg_color.rgba, false, false); 
		
		//window size 
		if (conf.one_ten_config){
			conf.minimum_width = spin_min_width.value.to_string();
			conf.minimum_height = spin_min_height.value.to_string();
		}
		else{
			conf.minimum_size = spin_min_width.value.to_string() + " " + spin_min_height.value.to_string();
		}
		conf.height_padding = (int) spin_height_padding.value;
		
		//time
		if(conf.time_format != ""){
			conf.time_format = gtk_combobox_get_value(cmb_time_format,1,"");
		}
		
		//network
		if(conf.network_device != ""){
			conf.network_device = txt_network_device.text;
		}
		
		//save changes to file
		conf.save_file();
		
		debug("-----------------------------------------------------");
		
		conf.start();
		
		gtk_set_busy(false, this);
	}
	
	private void btn_discard_changes_clicked () {
		reload_widget_properties();
	}
	
	private void btn_cancel_changes_clicked () {
		this.destroy();
	}
	
	private void cmb_transparency_type_changed(){
		switch (gtk_combobox_get_value(cmb_transparency_type,1,"semi")){
			case "semi":
				spin_opacity.sensitive = true;
				break;
			default:
				spin_opacity.sensitive = false;
				break;
		}
	}
}
