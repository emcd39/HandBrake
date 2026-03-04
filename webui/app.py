import os
import json
import uuid
import subprocess
import threading
import time
from flask import Flask, render_template, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = '/tmp/handbrake_uploads'
app.config['OUTPUT_FOLDER'] = '/tmp/handbrake_outputs'

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['OUTPUT_FOLDER'], exist_ok=True)

jobs = {}
job_progress = {}

def parse_scan_output(output):
    titles = []
    lines = output.split('\n')
    current_title = None
    
    for line in lines:
        if '+ title' in line and ':' in line:
            if current_title:
                titles.append(current_title)
            title_num = line.split('+ title')[1].split(':')[0].strip()
            current_title = {'id': int(title_num), 'name': f'Title {title_num}', 'tracks': []}
        elif current_title and '+ duration:' in line:
            duration = line.split('duration:')[1].strip()
            current_title['duration'] = duration
        elif current_title and '+ video track' in line:
            current_title['has_video'] = True
        elif current_title and '+ audio' in line:
            current_title['tracks'].append(line.strip())
    
    if current_title:
        titles.append(current_title)
    
    return titles

def run_encode_job(job_id, params):
    cmd = [
        'HandBrakeCLI',
        '-i', params['input'],
        '-o', params['output'],
        '-e', params.get('encoder', 'x264'),
        '-q', str(params.get('quality', 20)),
        '--vfr',
    ]
    
    if params.get('width'):
        cmd.extend(['-w', str(params['width'])])
    if params.get('height'):
        cmd.extend(['-l', str(params['height'])])
    if params.get('format'):
        cmd.extend(['-f', params['format']])
    if params.get('audio_encoder'):
        cmd.extend(['-a', '1', '-E', params['audio_encoder']])
    if params.get('audio_bitrate'):
        cmd.extend(['-B', str(params['audio_bitrate'])])
    if params.get('chapter_start'):
        cmd.extend(['--chapter-start', str(params['chapter_start'])])
    if params.get('chapter_end'):
        cmd.extend(['--chapter-end', str(params['chapter_end'])])
    
    job_progress[job_id] = {'status': 'running', 'progress': 0, 'pid': None}
    
    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True
        )
        
        job_progress[job_id]['pid'] = process.pid
        
        for line in process.stdout:
            if 'Encoding:' in line or '%' in line:
                try:
                    if '%' in line:
                        idx = line.rfind('%')
                        start = max(0, idx - 5)
                        end = min(len(line), idx + 1)
                        pct_str = line[start:end].strip().replace('%', '')
                        pct = float(pct_str)
                        job_progress[job_id]['progress'] = pct
                except:
                    pass
            job_progress[job_id]['last_line'] = line.strip()
        
        process.wait()
        
        if process.returncode == 0:
            job_progress[job_id]['status'] = 'completed'
            job_progress[job_id]['progress'] = 100
        else:
            job_progress[job_id]['status'] = 'failed'
            job_progress[job_id]['error'] = f'Exit code: {process.returncode}'
            
    except Exception as e:
        job_progress[job_id]['status'] = 'failed'
        job_progress[job_id]['error'] = str(e)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/scan', methods=['POST'])
def scan():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)
    
    cmd = ['HandBrakeCLI', '-i', filepath, '--title', '0', '--scan']
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        titles = parse_scan_output(result.stdout)
        return jsonify({'titles': titles, 'filepath': filepath})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/encode', methods=['POST'])
def encode():
    data = request.json
    
    job_id = str(uuid.uuid4())
    
    input_path = data.get('input')
    output_filename = data.get('output', 'output.mp4')
    output_path = os.path.join(app.config['OUTPUT_FOLDER'], output_filename)
    
    params = {
        'input': input_path,
        'output': output_path,
        'encoder': data.get('encoder', 'x264'),
        'quality': data.get('quality', 20),
        'width': data.get('width'),
        'height': data.get('height'),
        'format': data.get('format', 'mp4'),
        'audio_encoder': data.get('audio_encoder', 'aac'),
        'audio_bitrate': data.get('audio_bitrate', 128),
        'chapter_start': data.get('chapter_start'),
        'chapter_end': data.get('chapter_end'),
    }
    
    jobs[job_id] = params
    
    thread = threading.Thread(target=run_encode_job, args=(job_id, params))
    thread.start()
    
    return jsonify({'job_id': job_id, 'status': 'started'})

@app.route('/api/status/<job_id>')
def status(job_id):
    if job_id not in job_progress:
        return jsonify({'error': 'Job not found'}), 404
    
    return jsonify(job_progress[job_id])

@app.route('/api/jobs')
def list_jobs():
    return jsonify({'jobs': list(jobs.keys()), 'progress': job_progress})

@app.route('/api/cancel/<job_id>', methods=['POST'])
def cancel(job_id):
    if job_id not in job_progress:
        return jsonify({'error': 'Job not found'}), 404
    
    if job_progress[job_id].get('pid'):
        try:
            import signal
            os.kill(job_progress[job_id]['pid'], signal.SIGTERM)
            job_progress[job_id]['status'] = 'cancelled'
        except:
            pass
    
    return jsonify({'status': 'cancelled'})

@app.route('/download/<filename>')
def download(filename):
    return send_from_directory(app.config['OUTPUT_FOLDER'], filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
