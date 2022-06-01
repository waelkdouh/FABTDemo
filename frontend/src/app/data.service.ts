import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Todoitem } from './todoitem';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class DataService {

  private REST_API_SERVER = environment.REST_API_SERVER;

  constructor(private httpClient: HttpClient) { }

  public sendGetRequest(){
    return this.httpClient.get<Todoitem[]>(this.REST_API_SERVER);
  }
}