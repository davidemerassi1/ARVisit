import SwiftUI

struct PoiDetailView: View {
    @Binding var poi: Poi?
    @State var img: UIImage?
    let viewModel: RoomViewModel

    var body: some View {
        if let poi {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if let img {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }

                        Text(poi.name)
                            .font(.title)
                            .bold()
                            .padding(.horizontal)

                        if let audioguideUrl = poi.audioguideUrl {
                            Text("AUDIOGUIDA")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 20)
                                    .padding(.horizontal)

                            AudioPlayerView(audioURL: audioguideUrl)
                                .padding(.horizontal)
                        }
                        
                        if (!poi.description.isEmpty) {
                            Text("DESCRIZIONE")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.top, 20)
                                .padding(.horizontal)
                            
                            Text(poi.description)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.white))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                        }
                        
                        if (!poi.linkToDescription.isEmpty) {
                            Link("Maggiori informazioni", destination: URL(string: poi.linkToDescription)!)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.white))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                        }

                        Spacer()
                    }
                }
                .navigationTitle(poi.name) // Titolo visibile nella barra
                .navigationBarTitleDisplayMode(.inline) // Per farlo comparire mentre si scrolla
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fine") {
                            self.poi = nil
                        }
                    }
                }
                .background(Color(.systemGray6))
                .task {
                    if let url = poi.imageUrl, img == nil {
                        self.img = viewModel.getImage(url: url)
                    }
                }
            }
        }
    }
}
