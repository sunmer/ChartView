//
//  LineView.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 02..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct LineView: View {
    @ObservedObject var data: ChartData
    public var title: String?
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var valueSpecifier:String
    public var valueChangeCallback: (((Int)?) -> Void)?
    public var onGestureEndedCallback: (() -> Void)?
    @State public var currentIndex: Int = 0
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var showLegend = false
    @State private var dragLocation:CGPoint = .zero
    @State private var indicatorLocation:CGPoint = .zero
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity:Double = 0
    @State private var currentDataNumber: Double = 0
    
    public init(data: [Double],
                title: String? = nil,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                valueSpecifier: String? = "%.1f",
                valueChangeCallback: (((Int)?) -> Void)? = nil,
                onGestureEndedCallback: (() -> Void)? = nil) {
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.valueSpecifier = valueSpecifier!
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.valueChangeCallback = valueChangeCallback
        self.onGestureEndedCallback = onGestureEndedCallback
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            VStack(spacing: 0) {
                Group{
                    if (self.title != nil){
                        Text(self.title!)
                            .font(.system(size: 18, weight: .bold))
                            .bold().foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if (self.legend != nil){
                        Text(self.legend!)
                            .font(.callout)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                    }
                }.offset(x: 0, y: 0)
                ZStack{
                    GeometryReader{ reader in
                        Rectangle()
                            .foregroundColor(self.style.backgroundColor)
                        if(self.showLegend){
                            Legend(data: self.data,
                                   frame: .constant(reader.frame(in: .local)), valueSpecifier: self.valueSpecifier)
                                .transition(.opacity)
                                .animation(Animation.easeOut(duration: 1).delay(1))
                        }
                        Line(data: self.data,
                             frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 30, height: reader.frame(in: .local).height)),
                             touchLocation: self.$indicatorLocation,
                             minDataValue: .constant(nil),
                             maxDataValue: .constant(nil),
                             showBackground: false,
                             gradient: self.style.gradientColor
                        )
                        .offset(x: 30, y: -20)
                        .onAppear(){
                            self.showLegend = true
                        }
                        .onDisappear(){
                            self.showLegend = false
                        }
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: 240)
                    .offset(x: 0, y: 40)
                }
                .frame(width: geometry.frame(in: .local).size.width, height: 240)
                .gesture(DragGesture()
                .onChanged({ value in
                    self.dragLocation = value.location
                    self.indicatorLocation = CGPoint(x: max(value.location.x-30,0), y: 32)
                    self.opacity = 1
                    self.closestPoint = self.getClosestDataPoint(toPoint: value.location, width: geometry.frame(in: .local).size.width-30, height: 240)
                    if let callback = self.valueChangeCallback {
                        callback(self.currentIndex)
                    }
                })
                .onEnded({ value in
                    self.opacity = 0
                    if let callback = self.onGestureEndedCallback {
                        callback()
                    }
                })
                )
            }
        }
    }
    
    func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        let index = Int(floor((toPoint.x-15)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentIndex = index
            self.currentDataNumber = points[self.currentIndex]
            return CGPoint(x: CGFloat(self.currentIndex)*stepWidth, y: CGFloat(points[self.currentIndex])*stepHeight)
        }
        return .zero
    }
}

struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineView(data: [8,23,54,32,12,37,7,23,43], title: "Full chart", style: Styles.lineChartStyleOne)
            
            LineView(data: [282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 284.652, 284.129, 284.188], title: "Full chart", style: Styles.lineChartStyleOne)
            
        }
    }
}

