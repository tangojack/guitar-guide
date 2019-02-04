chords_cmajor = {
            "CMajor": [
                {
                    "root-position": [2,1],
                    "notes": [[3,0], [2,1], [1,0]],
                    "inversion": 2
                },
                {
                    "root-position": [3,5],
                    "notes": [[3,5], [2,5], [1,4]],
                    "inversion": 0
                },
                {
                    "root-position": [1,8],
                    "notes": [[3,9], [2,8], [1,8]],
                    "inversion": 1
                },
                {
                    "root-position": [2,1],
                    "notes": [[4,2], [3,0], [2,1]],
                    "inversion": 1
                },
                {
                    "root-position": [3,5],
                    "notes": [[4,5], [3,5], [2,5]],
                    "inversion": 2
                },
                {
                    "root-position": [4,10],
                    "notes": [[4,10], [3,9], [2,8]],
                    "inversion": 0
                },
                {
                    "root-position": [5,3],
                    "notes": [[5,3], [4,2], [3,0]],
                    "inversion": 0
                },
                {
                    "root-position": [3,5],
                    "notes": [[5,7], [4,5], [3,5]],
                    "inversion": 1
                },
                {
                    "root-position": [4,10],
                    "notes": [[5,10], [4,10], [3,9]],
                    "inversion": 2
                },
                {
                    "root-position": [5,3],
                    "notes": [[6,3], [5,3], [4,2]],
                    "inversion": 2
                },
                {
                    "root-position": [6,8],
                    "notes": [[6,8], [5,7], [4,5]],
                    "inversion": 0
                },
                {
                    "root-position": [4,10],
                    "notes": [[6,12], [5,10], [4,10]],
                    "inversion": 1
                },
                {
                    "root-position": [2,13],
                    "notes": [[3,12], [2,13], [1,12]],
                    "inversion": 2
                },
                {
                    "root-position": [3,17],
                    "notes": [[3,17], [2,17], [1,15]],
                    "inversion": 0
                },
                {
                    "root-position": [1,20],
                    "notes": [[3,21], [2,20], [1,20]],
                    "inversion": 1
                },
                {
                    "root-position": [2,13],
                    "notes": [[4,14], [3,12], [2,13]],
                    "inversion": 1
                },
                {
                    "root-position": [3,17],
                    "notes": [[4,17], [3,17], [2,17]],
                    "inversion": 2
                },
                {
                    "root-position": [4,22],
                    "notes": [[4,22], [3,21], [2,20]],
                    "inversion": 0
                },
                {
                    "root-position": [5,15],
                    "notes": [[5,15], [4,14], [3,12]],
                    "inversion": 0
                },
                {
                    "root-position": [3,17],
                    "notes": [[5,19], [4,17], [3,17]],
                    "inversion": 1
                },
                {
                    "root-position": [4,22],
                    "notes": [[5,22], [4,22], [3,21]],
                    "inversion": 2
                },
                {
                    "root-position": [5,15],
                    "notes": [[6,15], [5,15], [4,14]],
                    "inversion": 2
                },
                {
                    "root-position": [6,20],
                    "notes": [[6,20], [5,19], [4,17]],
                    "inversion": 0
                },
                {
                    "root-position": [6,23],
                    "notes": [[6,23], [5,21], [4,21]],
                    "inversion": 0
                }
            ]
        }

def find_chords(type, string, fret):
    chords_to_show = []
    for chord in chords_cmajor[type]:
        if chord['root-position'][0] is string and chord['root-position'][1] is fret:
            chords_to_show.append(chord)

    for chord in chords_to_show:
        print(chord)

find_chords("CMajor", 2, 1)
