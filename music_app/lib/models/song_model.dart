class SongModel {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String data; // File path
  final int? duration;

  SongModel({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.data,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'data': data,
      'duration': duration,
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      data: json['data'],
      duration: json['duration'],
    );
  }
}
