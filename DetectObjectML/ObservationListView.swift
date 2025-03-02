//
//  ObservationListView.swift
//  DetectObjectML
//
//  Created by Petar  on 2.3.25..
//

import SwiftUI

struct ObservationListView: View {
    
    let observations: [Observation]
    
    var body: some View {
        List(observations, id: \.label) { observation in
            HStack {
                Text(observation.label)
                Spacer()
                Text(NSNumber(value: observation.confidence), formatter: NumberFormatter.percentage)
            }
        }
    }
}

#Preview {
    ObservationListView(observations: [])
}
