﻿<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Map1.aspx.cs" Inherits="HighchartsExample.Map1" %>
<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="map/css/jquery-ui.css" rel="stylesheet"/>
    <link href="map/css/font-awesome.css" rel="stylesheet"/>
    <link href="map/css/map.css" rel="stylesheet"/>

    <script type="text/javascript" src="js/jquery-1.8.3.min.js"></script>
    <script type="text/javascript" src="map/js/highmaps.js"></script>
    <script type="text/javascript" src="map/js/index.js"></script>
    <script type="text/javascript" src="map/js/jquery-ui.js"></script>
    <script type="text/javascript" src="map/js/jquery.combobox.js"></script>
    <script type="text/javascript">
        $(function () {
            var baseMapPath = "http://code.highcharts.com/mapdata/",
            showDataLabels = false, // Switch for data labels enabled/disabled
            mapCount = 0,
            searchText,
            mapOptions = '';

            // Populate dropdown menus and turn into jQuery UI widgets
            $.each(Highcharts.mapDataIndex, function (mapGroup, maps) {
                if (mapGroup !== "version") {
                    mapOptions += '<option class="option-header">' + mapGroup + '</option>';
                    $.each(maps, function (desc, path) {
                        mapOptions += '<option value="' + path + '">' + desc + '</option>';
                        mapCount += 1;
                    });
                }
            });
            searchText = 'Search ' + mapCount + ' maps';
            mapOptions = '<option value="custom/world.js">' + searchText + '</option>' + mapOptions;
            $("#mapDropdown").append(mapOptions).combobox();

            // Change map when item selected in dropdown
            $("#mapDropdown").change(function () {
                var $selectedItem = $("option:selected", this),
            mapDesc = $selectedItem.text(),
            mapKey = this.value.slice(0, -3),
            svgPath = baseMapPath + mapKey + '.svg',
            geojsonPath = baseMapPath + mapKey + '.geo.json',
            javascriptPath = baseMapPath + this.value,
            isHeader = $selectedItem.hasClass('option-header');

                // Dim or highlight search box
                if (mapDesc === searchText || isHeader) {
                    $('.custom-combobox-input').removeClass('valid');
                    location.hash = '';
                } else {
                    $('.custom-combobox-input').addClass('valid');
                    location.hash = mapKey;
                }

                if (isHeader) {
                    return false;
                }

                // Show loading
                if ($("#container").highcharts()) {
                    $("#container").highcharts().showLoading('<i class="fa fa-spinner fa-spin fa-2x"></i>');
                }


                // When the map is loaded or ready from cache...
                function mapReady() {

                    var mapGeoJSON = Highcharts.maps[mapKey],
                data = [],
                parent,
                match;

                    // Update info box download links
                    $("#download").html('<a class="button" target="_blank" href="http://www.highcharts.com/samples/maps-base.php?mapkey=' + mapKey + '">' +
                'View clean demo</a>' +
                '<div class="or-view-as">... or view as ' +
                '<a target="_blank" href="' + svgPath + '">SVG</a>, ' +
                '<a target="_blank" href="' + geojsonPath + '">GeoJSON</a>, ' +
                '<a target="_blank" href="' + javascriptPath + '">JavaScript</a>.</div>');

                    // Generate non-random data for the map
                    $.each(mapGeoJSON.features, function (index, feature) {
                        data.push({
                            key: feature.properties['hc-key'],
                            value: index
                        });
                    });

                    // Show arrows the first time a real map is shown
                    if (mapDesc !== searchText) {
                        $('.selector .prev-next').show();
                        $('#sideBox').show();
                    }

                    // Is there a layer above this?
                    match = mapKey.match(/^(countries\/[a-z]{2}\/[a-z]{2})-[a-z0-9]+-all$/);
                    if (/^countries\/[a-z]{2}\/[a-z]{2}-all$/.test(mapKey)) { // country
                        parent = {
                            desc: 'World',
                            key: 'custom/world'
                        };
                    } else if (match) { // admin1
                        parent = {
                            desc: $('option[value="' + match[1] + '-all.js"]').text(),
                            key: match[1] + '-all'
                        };
                    }
                    $('#up').html('');
                    if (parent) {
                        $('#up').append(
                    $('<a><i class="fa fa-angle-up"></i> ' + parent.desc + '</a>')
                        .attr({
                            title: parent.key
                        })
                        .click(function () {
                            $('#mapDropdown').val(parent.key + '.js').change();
                        })
                );
                    }


                    // Instantiate chart
                    $("#container").highcharts('Map', {

                        title: {
                            text: null
                        },

                        mapNavigation: {
                            enabled: true
                        },

                        colorAxis: {
                            min: 0,
                            stops: [
                        [0, '#EFEFFF'],
                        [0.5, Highcharts.getOptions().colors[0]],
                        [1, Highcharts.Color(Highcharts.getOptions().colors[0]).brighten(-0.5).get()]
                    ]
                        },

                        legend: {
                            layout: 'vertical',
                            align: 'left',
                            verticalAlign: 'bottom'
                        },

                        series: [{
                            data: data,
                            mapData: mapGeoJSON,
                            joinBy: ['hc-key', 'key'],
                            name: 'Random data',
                            states: {
                                hover: {
                                    color: Highcharts.getOptions().colors[2]
                                }
                            },
                            dataLabels: {
                                enabled: showDataLabels,
                                formatter: function () {
                                    return mapKey === 'custom/world' || mapKey === 'countries/us/us-all' ?
                                    (this.point.properties && this.point.properties['hc-a2']) :
                                    this.point.name;
                                }
                            },
                            point: {
                                events: {
                                    // On click, look for a detailed map
                                    click: function () {
                                        var key = this.key;
                                        $('#mapDropdown option').each(function () {
                                            if (this.value === 'countries/' + key.substr(0, 2) + '/' + key + '-all.js') {
                                                $('#mapDropdown').val(this.value).change();
                                            }
                                        });
                                    }
                                }
                            }
                        }, {
                            type: 'mapline',
                            name: "Separators",
                            data: Highcharts.geojson(mapGeoJSON, 'mapline'),
                            nullColor: 'gray',
                            showInLegend: false,
                            enableMouseTracking: false
                        }]
                    });

                    showDataLabels = $("#chkDataLabels").attr('checked');

                }

                // Check whether the map is already loaded, else load it and
                // then show it async
                if (Highcharts.maps[mapKey]) {
                    mapReady();
                } else {
                    $.getScript(javascriptPath, mapReady);
                }
            });

            // Toggle data labels - Note: Reloads map with new random data
            $("#chkDataLabels").change(function () {
                showDataLabels = $("#chkDataLabels").attr('checked');
                $("#mapDropdown").change();
            });

            // Switch to previous map on button click
            $("#btn-prev-map").click(function () {
                $("#mapDropdown option:selected").prev("option").prop("selected", true).change();
            });

            // Switch to next map on button click
            $("#btn-next-map").click(function () {
                $("#mapDropdown option:selected").next("option").prop("selected", true).change();
            });

            // Trigger change event to load map on startup
            if (location.hash) {
                $('#mapDropdown').val(location.hash.substr(1) + '.js');
            } else { // for IE9
                $($('#mapDropdown option')[0]).attr('selected', 'selected');
            }
            $('#mapDropdown').change();
        });
    </script>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div id="demo-wrapper">
    <div id="mapBox">
        <div id="up"></div>
        <div class="selector">
            <button id="btn-prev-map" class="prev-next"><i class="fa fa-angle-left"></i></button>
            <select id="mapDropdown" class="ui-widget combobox"></select>
            <button id="btn-next-map" class="prev-next"><i class="fa fa-angle-right"></i></button>
        </div>
        <div id="container"></div> 
    </div>
    <div id="sideBox">
        <input type="checkbox" id="chkDataLabels" checked='checked' />
        <label for="chkDataLabels" style="display: inline">Data labels</label>
        <div id="infoBox">
            <h4>This map</h4>
            <div id="download"></div>
        </div>
    </div>
</div>
</asp:Content>
