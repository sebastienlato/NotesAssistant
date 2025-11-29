import SwiftUI

struct TranscriptionView: View {
    @StateObject private var viewModel: TranscriptionViewModel

    init(viewModel: TranscriptionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("File")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(viewModel.audioURL.lastPathComponent)
                .font(.callout)
                .textSelection(.enabled)

            Button(action: viewModel.transcribe) {
                if viewModel.isTranscribing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                } else {
                    Text("Transcribe Recording")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(viewModel.isTranscribing)

            if viewModel.isTranscribing {
                Text("Transcribing…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let transcript = textToDisplay {
                Text("Transcript")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ScrollView {
                    Text(transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .frame(maxHeight: 300)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Transcription")
    }

    private var textToDisplay: String? {
        guard !viewModel.transcriptText.isEmpty else { return nil }
        return viewModel.transcriptText
    }
}

#Preview {
    let sampleURL = URL(fileURLWithPath: "/tmp/sample.m4a")
    TranscriptionView(
        viewModel: TranscriptionViewModel(
            audioURL: sampleURL,
            transcriptionService: TranscriptionService()
        )
    )
}
