#!/usr/bin/env python3
"""
Power BI Data Pack Generator: FinTech Credit Risk & Portfolio Vintage Analysis
Exports clean analytics tables into an Excel workbook for Power BI Desktop.
"""

import os
import pandas as pd

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'data')
OUT_DIR = os.path.join(BASE_DIR, 'powerbi')

def main():
    print("Preparing Power BI Data Pack for Credit Risk & Vintage Analysis...")
    
    df_clean = pd.read_csv(os.path.join(DATA_DIR, 'loan_portfolio_clean.csv'))
    df_vintage = pd.read_csv(os.path.join(DATA_DIR, 'vintage_loss_matrix.csv'))
    df_aging = pd.read_csv(os.path.join(DATA_DIR, 'delinquency_aging_summary.csv'))
    df_segments = pd.read_csv(os.path.join(DATA_DIR, 'borrower_risk_segments.csv'))
    
    excel_path = os.path.join(OUT_DIR, 'powerbi_credit_risk_dataset.xlsx')
    with pd.ExcelWriter(excel_path, engine='openpyxl') as writer:
        df_clean.head(4000).to_excel(writer, sheet_name='loans_fact', index=False)
        df_vintage.to_excel(writer, sheet_name='vintage_loss_matrix', index=False)
        df_aging.to_excel(writer, sheet_name='delinquency_aging', index=False)
        df_segments.to_excel(writer, sheet_name='borrower_risk_tiers', index=False)
        
    print(f"Generated Power BI Excel Workbook: {excel_path}")
    print("All risk tables and vintage matrices staged for Power BI Desktop.")

if __name__ == '__main__':
    main()
