from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO

def generate_health_pdf(pet_name, metric_name, analysis_data):
    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=letter)
    
    # 1. Header
    p.setFont("Helvetica-Bold", 20)
    p.drawString(100, 750, f"PetSync Clinical Health Report")
    
    # 2. Pet Info
    p.setFont("Helvetica", 12)
    p.drawString(100, 730, f"Patient Name: {pet_name}")
    p.drawString(100, 715, f"Metric Analyzed: {metric_name.capitalize()}")
    p.drawString(100, 700, f"Report Generated: {analysis_data.get('date', 'Today')}")
    
    p.line(100, 690, 500, 690)

    # 3. Status Summary
    is_risk = analysis_data.get('is_risk', False)
    status_text = "⚠️ ATTENTION REQUIRED" if is_risk else "✅ HEALTH STABLE"
    p.setFont("Helvetica-Bold", 14)
    p.drawString(100, 660, f"Status: {status_text}")
    
    p.setFont("Helvetica", 11)
    p.drawString(100, 640, f"Insight: {analysis_data.get('message', '')}")
    p.drawString(100, 625, f"Current Value: {analysis_data.get('current')} | Baseline: {analysis_data.get('baseline')}")

    # 4. Data Table (Simplified)
    p.drawString(100, 580, "Recent Log History:")
    y_offset = 560
    for pt in analysis_data.get('points', []):
        p.drawString(120, y_offset, f"- Value: {pt['y']} (Log Index: {pt['x']})")
        y_offset -= 15
        if y_offset < 100: break # Prevent overflow

    p.showPage()
    p.save()
    buffer.seek(0)
    return buffer